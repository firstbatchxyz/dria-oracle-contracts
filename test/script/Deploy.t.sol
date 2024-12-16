// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

import {DeployLLMOracleCoordinator, DeployLLMOracleRegistry} from "../../script/Deploy.s.sol";
import {LLMOracleRegistry} from "../../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator} from "../../src/LLMOracleCoordinator.sol";

contract DeployTest is Test {
    DeployLLMOracleCoordinator deployLLMOracleCoordinator;
    DeployLLMOracleRegistry deployLLMOracleRegistry;

    address llmOracleCoordinatorProxy;
    address llmOracleCoordinatorImpl;

    address llmOracleRegistryProxy;
    address llmOracleRegistryImpl;

    function setUp() external {
        deployLLMOracleRegistry = new DeployLLMOracleRegistry();
        (llmOracleRegistryProxy, llmOracleRegistryImpl) = deployLLMOracleRegistry.run();

        deployLLMOracleCoordinator = new DeployLLMOracleCoordinator();
        (llmOracleCoordinatorProxy, llmOracleCoordinatorImpl) = deployLLMOracleCoordinator.run();
    }

    modifier deployed() {
        // check deployed addresses are not zero
        require(llmOracleRegistryProxy != address(0), "LLMOracleRegistry not deployed");
        require(llmOracleRegistryImpl != address(0), "LLMOracleRegistry implementation not deployed");

        require(llmOracleCoordinatorProxy != address(0), "LLMOracleCoordinator not deployed");
        require(llmOracleCoordinatorImpl != address(0), "LLMOracleCoordinator implementation not deployed");

        // check if implementations are correct
        address expectedRegistryImpl = Upgrades.getImplementationAddress(llmOracleRegistryProxy);
        address expectedCoordinatorImpl = Upgrades.getImplementationAddress(llmOracleCoordinatorProxy);

        require(llmOracleRegistryImpl == expectedRegistryImpl, "LLMOracleRegistry implementation mismatch");
        require(llmOracleCoordinatorImpl == expectedCoordinatorImpl, "LLMOracleCoordinator implementation mismatch");
        require(address(LLMOracleCoordinator(llmOracleCoordinatorProxy).registry()) == llmOracleRegistryProxy, "LLMOracleCoordinator registry mismatch");
        _;
    }

    function test_Deploy() external deployed {}
}
