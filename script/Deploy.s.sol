// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {LLMOracleRegistry} from "../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator, LLMOracleTaskParameters} from "../src/LLMOracleCoordinator.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Vm} from "forge-std/Vm.sol";

contract Deploy is Script {
    // contracts
    LLMOracleCoordinator public oracleCoordinator;
    LLMOracleRegistry public oracleRegistry;

    // implementation addresses
    address registryImplementation;
    address coordinatorImplementation;

    HelperConfig public config;
    uint256 chainId;

    function run() external {
        chainId = block.chainid;
        config = new HelperConfig();

        vm.startBroadcast();
        deployLLM();
        vm.stopBroadcast();

        writeContractAddresses();
    }

    function deployLLM() internal {
        // get stakes
        (uint256 genStake, uint256 valStake) = config.stakes();

        // get fees
        (uint256 platformFee, uint256 genFee, uint256 valFee) = config.fees();

        // deploy llm contracts
        address registryProxy = Upgrades.deployUUPSProxy(
            "LLMOracleRegistry.sol",
            abi.encodeCall(
                LLMOracleRegistry.initialize,
                (genStake, valStake, address(config.token()), config.minRegistrationTime())
            )
        );

        // wrap proxy with the LLMOracleRegistry
        oracleRegistry = LLMOracleRegistry(registryProxy);
        registryImplementation = Upgrades.getImplementationAddress(registryProxy);

        // deploy coordinator contract
        address coordinatorProxy = Upgrades.deployUUPSProxy(
            "LLMOracleCoordinator.sol",
            abi.encodeCall(
                LLMOracleCoordinator.initialize,
                (
                    address(oracleRegistry),
                    address(config.token()),
                    platformFee,
                    genFee,
                    valFee,
                    config.minScore(),
                    config.maxScore()
                )
            )
        );

        oracleCoordinator = LLMOracleCoordinator(coordinatorProxy);
        coordinatorImplementation = Upgrades.getImplementationAddress(coordinatorProxy);
    }

    function writeContractAddresses() internal {
        // create a deployment file if not exist
        string memory dir = "deployment/";
        string memory fileName = Strings.toString(chainId);
        string memory path = string.concat(dir, fileName, ".json");

        // create dir if not exist
        vm.createDir(dir, true);

        string memory contracts = string.concat(
            "{",
            '  "LLMOracleRegistry": {',
            '    "proxyAddr": "',
            Strings.toHexString(uint256(uint160(address(oracleRegistry))), 20),
            '",',
            '    "implAddr": "',
            Strings.toHexString(uint256(uint160(address(registryImplementation))), 20),
            '"',
            "  },",
            '  "LLMOracleCoordinator": {',
            '    "proxyAddr": "',
            Strings.toHexString(uint256(uint160(address(oracleCoordinator))), 20),
            '",',
            '    "implAddr": "',
            Strings.toHexString(uint256(uint160(address(coordinatorImplementation))), 20),
            '"',
            "  }",
            "}"
        );

        vm.writeJson(contracts, path);
    }
}
