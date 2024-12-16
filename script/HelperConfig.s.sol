// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";

import {WETH9} from "../test/WETH9.sol";
import {LLMOracleTaskParameters} from "../src/LLMOracleTask.sol";
import {LLMOracleRegistry} from "../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator} from "../src/LLMOracleCoordinator.sol";

struct Stakes {
    uint256 generatorStakeAmount;
    uint256 validatorStakeAmount;
}

struct Fees {
    uint256 platformFee;
    uint256 generationFee;
    uint256 validationFee;
}

contract HelperConfig is Script {
    LLMOracleTaskParameters public taskParams;

    Stakes public stakes;
    Fees public fees;
    WETH9 public token;

    uint256 public minRegistrationTime; // in seconds
    uint256 public minScore;
    uint256 public maxScore;

    constructor() {
        // set deployment parameters
        stakes = Stakes({generatorStakeAmount: 0.0001 ether, validatorStakeAmount: 0.000001 ether});
        fees = Fees({platformFee: 0.0001 ether, generationFee: 0.0001 ether, validationFee: 0.0001 ether});
        taskParams = LLMOracleTaskParameters({difficulty: 2, numGenerations: 1, numValidations: 1});

        minRegistrationTime = 1 days;
        maxScore = type(uint8).max; // 255
        minScore = 1;

        // use deployed weth
        token = WETH9(payable(0x4200000000000000000000000000000000000006));
    }

    function deployLLMOracleRegistry() external returns (address proxy, address impl) {
        vm.startBroadcast();

        // deploy llm contracts
        address registryProxy = Upgrades.deployUUPSProxy(
            "LLMOracleRegistry.sol",
            abi.encodeCall(
                LLMOracleRegistry.initialize,
                (stakes.generatorStakeAmount, stakes.validatorStakeAmount, address(token), minRegistrationTime)
            )
        );

        address registryImplementation = Upgrades.getImplementationAddress(registryProxy);
        vm.stopBroadcast();

        writeProxyAddresses("LLMOracleRegistry", registryProxy, registryImplementation);

        return (registryProxy, registryImplementation);
    }

    function deployLLMOracleCoordinator() external returns (address proxy, address impl) {
        // get the registry proxy address from chainid.json file under the deployment dir
        string memory dir = "deployment/";
        string memory fileName = Strings.toString(block.chainid);
        string memory path = string.concat(dir, fileName, ".json");

        string memory contractAddresses = vm.readFile(path);
        bool isRegistryExist = vm.keyExistsJson(contractAddresses, "$.LLMOracleRegistry");
        require(isRegistryExist, "Please deploy LLMOracleRegistry first");

        address registryProxy = vm.parseJsonAddress(contractAddresses, "$.LLMOracleRegistry.proxyAddr");
        require(registryProxy != address(0), "LLMOracleRegistry proxy address is invalid");

        address registryImlp = vm.parseJsonAddress(contractAddresses, "$.LLMOracleRegistry.implAddr");
        require(registryImlp != address(0), "LLMOracleRegistry implementation address is invalid");

        vm.startBroadcast();
        // deploy coordinator contract
        address coordinatorProxy = Upgrades.deployUUPSProxy(
            "LLMOracleCoordinator.sol",
            abi.encodeCall(
                LLMOracleCoordinator.initialize,
                (
                    registryProxy,
                    address(token),
                    fees.platformFee,
                    fees.generationFee,
                    fees.validationFee,
                    minScore,
                    maxScore
                )
            )
        );

        address coordinatorImplementation = Upgrades.getImplementationAddress(coordinatorProxy);

        vm.stopBroadcast();
        writeProxyAddresses("LLMOracleCoordinator", coordinatorProxy, coordinatorImplementation);

        return (coordinatorProxy, coordinatorImplementation);
    }

    function writeProxyAddresses(string memory name, address proxy, address impl) internal {
        // create a deployment file if not exist
        string memory dir = "deployment/";
        string memory fileName = Strings.toString(block.chainid);
        string memory path = string.concat(dir, fileName, ".json");

        string memory proxyAddr = Strings.toHexString(uint256(uint160(proxy)), 20);
        string memory implAddr = Strings.toHexString(uint256(uint160(impl)), 20);

        // create dir if it doesn't exist
        vm.createDir(dir, true);

        // create file if it doesn't exist
        if (!vm.isFile(path)) {
            vm.writeFile(path, "");
        }

        // create a new JSON object
        string memory newContract =
            string.concat('"', name, '": {', '  "proxyAddr": "', proxyAddr, '",', '  "implAddr": "', implAddr, '"', "}");

        // read file content
        string memory contractAddresses = vm.readFile(path);

        // if the file is not empty, check key exists
        if (bytes(contractAddresses).length == 0) {
            // write the new contract to the file
            vm.writeJson(string.concat("{", newContract, "}"), path);
        } else {
            // check if the key exists
            bool isExist = vm.keyExistsJson(contractAddresses, string.concat("$.", name));

            if (isExist) {
                // update values
                vm.writeJson(proxyAddr, path, string.concat("$.", name, ".proxyAddr"));
                vm.writeJson(implAddr, path, string.concat("$.", name, ".implAddr"));
            } else {
                // Remove the last character '}' from the existing JSON string
                bytes memory contractBytes = bytes(contractAddresses);
                contractBytes[contractBytes.length - 1] = bytes1(",");

                // Append the new contract object and close the JSON
                string memory updatedContracts = string.concat(contractAddresses, newContract, "}");
                // write the updated JSON to the file
                vm.writeJson(updatedContracts, path);
            }
        }
    }
}
