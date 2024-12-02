// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Helper} from "./Helper.t.sol";

import {LLMOracleRegistry, LLMOracleKind} from "../src/LLMOracleRegistry.sol";
import {WETH9} from "./WETH9.sol";

contract LLMOracleRegistryTest is Helper {
    uint256 totalStakeAmount;
    address oracle;

    modifier deployment() {
        oracle = generators[0];
        totalStakeAmount = stakes.generatorStakeAmount + stakes.validatorStakeAmount;

        token = new WETH9();

        vm.startPrank(dria);
        address registryProxy = Upgrades.deployUUPSProxy(
            "LLMOracleRegistry.sol",
            abi.encodeCall(
                LLMOracleRegistry.initialize,
                (stakes.generatorStakeAmount, stakes.validatorStakeAmount, address(token), minRegistrationTime)
            )
        );

        // wrap proxy with the LLMOracleRegistry contract to use in tests easily
        oracleRegistry = LLMOracleRegistry(registryProxy);
        vm.stopPrank();

        assertEq(oracleRegistry.generatorStakeAmount(), stakes.generatorStakeAmount);
        assertEq(oracleRegistry.validatorStakeAmount(), stakes.validatorStakeAmount);
        assertEq(oracleRegistry.minRegistrationTime(), minRegistrationTime);

        assertEq(address(oracleRegistry.token()), address(token));
        assertEq(oracleRegistry.owner(), dria);

        vm.label(oracle, "Oracle");
        vm.label(address(this), "LLMOracleRegistryTest");
        vm.label(address(oracleRegistry), "LLMOracleRegistry");
        vm.label(address(oracleCoordinator), "LLMOracleCoordinator");
        vm.label(address(token), "WETH9");
        _;
    }

    /// @notice fund the oracle and dria
    modifier fund() {
        deal(address(token), dria, 1 ether);
        deal(address(token), oracle, totalStakeAmount);

        assertEq(token.balanceOf(dria), 1 ether);
        assertEq(token.balanceOf(oracle), totalStakeAmount);
        _;
    }

    /// @notice register oracle with kind
    modifier registerOracle(LLMOracleKind kind) {
        if (kind == LLMOracleKind.Validator) {
            // add generators to whitelist
            vm.prank(dria);
            oracleRegistry.addToWhitelist(generators);
        }

        vm.startPrank(oracle);
        // approve the registry to spend tokens on behalf of the oracle
        token.approve(address(oracleRegistry), totalStakeAmount);

        // register oracle
        oracleRegistry.register(kind);
        vm.stopPrank();
        _;
    }

    /// @notice unregister oracle with kind
    function unregisterOracle(LLMOracleKind kind) internal {
        // simulate the oracle account
        vm.startPrank(oracle);
        token.approve(address(oracleRegistry), stakes.generatorStakeAmount);
        oracleRegistry.unregister(kind);
        vm.stopPrank();

        assertFalse(oracleRegistry.isRegistered(oracle, LLMOracleKind.Generator));
    }

    /// @notice Remove oracle from whitelist
    function test_RemoveFromWhitelist() external deployment fund registerOracle(LLMOracleKind.Validator) {
        vm.prank(dria);
        oracleRegistry.removeFromWhitelist(validators[1]);
        vm.assertFalse(oracleRegistry.whitelisted(validators[1]));
    }

    /// @notice Registry has not approved by oracle
    function test_RevertWhen_RegistryHasNotApprovedByOracle() external deployment {
        // oracle has the funds but has not approved yet
        deal(address(token), oracle, totalStakeAmount);

        vm.expectRevert(abi.encodeWithSelector(LLMOracleRegistry.InsufficientFunds.selector));
        oracleRegistry.register(LLMOracleKind.Generator);
    }

    /// @notice Oracle has enough funds and approve registry
    function test_RegisterGeneratorOracle() external deployment fund registerOracle(LLMOracleKind.Generator) {}

    /// @notice Same oracle try to register twice
    function test_RevertWhen_RegisterSameGeneratorTwice()
        external
        deployment
        fund
        registerOracle(LLMOracleKind.Generator)
    {
        vm.prank(oracle);
        vm.expectRevert(abi.encodeWithSelector(LLMOracleRegistry.AlreadyRegistered.selector, oracle));

        oracleRegistry.register(LLMOracleKind.Generator);
    }

    /// @notice Oracle registers as validator
    function test_RegisterValidatorOracle() external deployment fund registerOracle(LLMOracleKind.Validator) {}

    /// @notice Oracle try to unregister without enough time has passed
    function test_RevertWhen_UnregisterBeforeEnoughTimeHasPassed()
        external
        deployment
        fund
        registerOracle(LLMOracleKind.Generator)
    {
        vm.startPrank(oracle);
        token.approve(address(oracleRegistry), stakes.generatorStakeAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                LLMOracleRegistry.TooEarlyToUnregister.selector,
                block.timestamp - oracleRegistry.registrationTimes(oracle)
            )
        );
        oracleRegistry.unregister(LLMOracleKind.Generator);
        vm.stopPrank();
    }

    /// @notice Oracle unregisteration as generator
    function test_UnregisterOracle() external deployment fund registerOracle(LLMOracleKind.Generator) {
        vm.warp(minRegistrationTime + 1);
        unregisterOracle(LLMOracleKind.Generator);
    }

    /// @notice Oracle try to unregister as generator twice
    function test_RevertWhen_UnregisterSameGeneratorTwice()
        external
        deployment
        fund
        registerOracle(LLMOracleKind.Generator)
    {
        vm.warp(minRegistrationTime + 1);
        unregisterOracle(LLMOracleKind.Generator);

        vm.prank(oracle);
        vm.expectRevert(abi.encodeWithSelector(LLMOracleRegistry.NotRegistered.selector, oracle));
        oracleRegistry.unregister(LLMOracleKind.Generator);
    }

    /// @notice Oracle can withdraw stakes after unregistering
    /// @dev 1. Register as generator
    /// @dev 2. Register as validator
    /// @dev 3. Unregister as generator
    /// @dev 4. Unregister as validator
    /// @dev 5. withdraw stakes
    function test_WithdrawStakesAfterUnregistering()
        external
        deployment
        fund
        addValidatorsToWhitelist
        registerOracle(LLMOracleKind.Generator)
        registerOracle(LLMOracleKind.Validator)
    {
        vm.warp(minRegistrationTime + 1);
        unregisterOracle(LLMOracleKind.Generator);
        unregisterOracle(LLMOracleKind.Validator);

        uint256 balanceBefore = token.balanceOf(oracle);
        token.approve(address(oracleRegistry), totalStakeAmount);

        // withdraw stakes
        vm.startPrank(oracle);
        token.transferFrom(address(oracleRegistry), oracle, (totalStakeAmount));

        uint256 balanceAfter = token.balanceOf(oracle);
        assertEq(balanceAfter - balanceBefore, totalStakeAmount);
    }
}
