// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import {HelperConfig} from "./HelperConfig.s.sol";
import {LLMOracleRegistry} from "../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator, LLMOracleTaskParameters} from "../src/LLMOracleCoordinator.sol";

contract DeployLLMOracleRegistry is Script {
    HelperConfig public config;

    function run() external returns (address proxy, address impl) {
        config = new HelperConfig();
        (proxy, impl) = config.deployLLMOracleRegistry();
    }
}

contract DeployLLMOracleCoordinator is Script {
    HelperConfig public config;

    function run() external returns (address proxy, address impl) {
        config = new HelperConfig();
        (proxy, impl) = config.deployLLMOracleCoordinator();
    }
}
