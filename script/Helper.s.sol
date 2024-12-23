// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";

import {LLMOracleRegistry} from "../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator} from "../src/LLMOracleCoordinator.sol";

contract Helper is Script {
    /// @notice Returns the deployment JSON file w.r.t chain id.
    /// @dev You are expect to use JSON-related commands with the returned string,
    /// see https://book.getfoundry.sh/cheatcodes/external for more.
    function getDeploymentsJson() external view returns (string memory) {
        string memory chainId = Strings.toString(block.chainid);
        string memory path = string.concat("deployments/", chainId, "addresses.json");

        return vm.readFile(path);
    }

    function writeProxyAddresses(string memory name, address _proxy, address _impl) external {
        // create a deployment file if not exist
        string memory dir = "deployments/";
        string memory chainId = Strings.toString(block.chainid);
        string memory path = string.concat(dir, chainId, ".json");

        string memory proxy = Strings.toHexString(uint256(uint160(_proxy)), 20);
        string memory impl = Strings.toHexString(uint256(uint160(_impl)), 20);

        // create dir if it doesn't exist
        vm.createDir(dir, true);

        // create file if it doesn't exist
        if (!vm.isFile(path)) {
            vm.writeFile(path, "");
        }

        // read file content
        string memory deployments = vm.readFile(path);

        // create a new JSON object
        string memory newContract =
            string.concat('"', name, '": {', '  "proxyAddr": "', proxy, '",', '  "implAddr": "', impl, '"', "}");

        // if the file is not empty, check key exists
        if (bytes(deployments).length == 0) {
            // write the new contract to the file
            vm.writeJson(string.concat("{", newContract, "}"), path);
        } else {
            // check if the key exists
            bool isExist = vm.keyExistsJson(deployments, string.concat("$.", name));

            if (isExist) {
                // update values
                vm.writeJson(proxy, path, string.concat("$.", name, ".proxyAddr"));
                vm.writeJson(impl, path, string.concat("$.", name, ".implAddr"));
            } else {
                // replace last character `}` with `,` in JSON
                bytes memory deploymentsBytes = bytes(deployments);
                deploymentsBytes[deploymentsBytes.length - 1] = bytes1(",");

                // Append the new contract object and close the JSON
                string memory newDeployments = string.concat(deployments, newContract, "}");
                // write the updated JSON to the file
                vm.writeJson(newDeployments, path);
            }
        }
    }
}
