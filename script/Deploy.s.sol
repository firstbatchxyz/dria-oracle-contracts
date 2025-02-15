// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Upgrades, Options} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import {Helper} from "./Helper.s.sol";
import {LLMOracleRegistry} from "../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator, LLMOracleTaskParameters} from "../src/LLMOracleCoordinator.sol";

struct Stakes {
    uint256 generator;
    uint256 validator;
}

contract DeployLLMOracleRegistry is Script {
    Helper public helper;
    Stakes public stakes;
    uint256 public minRegistrationTimeSec;
    address public token;

    constructor() {
        helper = new Helper();

        // parameters
        minRegistrationTimeSec = 1 days;
        stakes = Stakes({generator: 0.0001 ether, validator: 0.000001 ether});
        token = address(0x4200000000000000000000000000000000000006); // WETH
    }

    function run() external returns (address proxy, address impl) {
        vm.startBroadcast();
        (proxy, impl) = deploy();
        vm.stopBroadcast();

        helper.writeProxyAddresses("LLMOracleRegistry", proxy, impl);
    }

    function deploy() public returns (address proxy, address impl) {
        proxy = Upgrades.deployUUPSProxy(
            "LLMOracleRegistry.sol",
            abi.encodeCall(
                LLMOracleRegistry.initialize, (stakes.generator, stakes.validator, token, minRegistrationTimeSec)
            )
        );

        impl = Upgrades.getImplementationAddress(proxy);
    }
}

contract DeployLLMOracleCoordinator is Script {
    Helper public helper;
    Fees public fees;
    address public token;
    uint256 public minScore;
    uint256 public maxScore;
    LLMOracleTaskParameters public taskParams;

    struct Fees {
        uint256 platform;
        uint256 generation;
        uint256 validation;
    }

    constructor() {
        helper = new Helper();

        fees = Fees({platform: 0.0001 ether, generation: 0.0001 ether, validation: 0.0001 ether});
        maxScore = type(uint8).max; // 255
        minScore = 1;
        token = address(0x4200000000000000000000000000000000000006);
    }

    function run() public {
        // read registry address
        string memory deployments = helper.getDeploymentsJson();
        require(vm.keyExistsJson(deployments, "$.LLMOracleRegistry"), "Please deploy LLMOracleRegistry first");
        address registryProxy = vm.parseJsonAddress(deployments, "$.LLMOracleRegistry.proxyAddr");
        require(registryProxy != address(0), "LLMOracleRegistry proxy address is invalid");
        address registryImlp = vm.parseJsonAddress(deployments, "$.LLMOracleRegistry.implAddr");
        require(registryImlp != address(0), "LLMOracleRegistry implementation address is invalid");

        vm.startBroadcast();
        (address proxy, address impl) = deploy(registryProxy);
        vm.stopBroadcast();

        helper.writeProxyAddresses("LLMOracleCoordinator", proxy, impl);
    }

    function deploy(address registryAddr) public returns (address proxy, address impl) {
        proxy = Upgrades.deployUUPSProxy(
            "LLMOracleCoordinator.sol",
            abi.encodeCall(
                LLMOracleCoordinator.initialize,
                (registryAddr, token, fees.platform, fees.generation, fees.validation, minScore, maxScore)
            )
        );

        impl = Upgrades.getImplementationAddress(proxy);
    }
}
