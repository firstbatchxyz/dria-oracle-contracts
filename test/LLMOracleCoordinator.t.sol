// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Helper} from "./Helper.t.sol";

import {LLMOracleTask, LLMOracleTaskParameters} from "../src/LLMOracleTask.sol";
import {LLMOracleRegistry, LLMOracleKind} from "../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator} from "../src/LLMOracleCoordinator.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {WETH9} from "./WETH9.sol";

contract LLMOracleCoordinatorTest is Helper {
    address dummy = vm.addr(20);
    address requester = vm.addr(21);
    bytes output = "0x";

    modifier deployment() {
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

        // deploy coordinator contract
        address coordinatorProxy = Upgrades.deployUUPSProxy(
            "LLMOracleCoordinator.sol",
            abi.encodeCall(
                LLMOracleCoordinator.initialize,
                (
                    address(oracleRegistry),
                    address(token),
                    fees.platformFee,
                    fees.generationFee,
                    fees.validationFee,
                    minScore,
                    maxScore
                )
            )
        );
        oracleCoordinator = LLMOracleCoordinator(coordinatorProxy);
        vm.stopPrank();

        vm.label(dummy, "Dummy");
        vm.label(requester, "Requester");
        vm.label(address(this), "LLMOracleCoordinatorTest");
        vm.label(address(oracleRegistry), "LLMOracleRegistry");
        vm.label(address(oracleCoordinator), "LLMOracleCoordinator");
        vm.label(address(token), "WETH9");
        _;
    }

    modifier fund() {
        // deploy weth
        token = new WETH9();

        // fund dria & requester
        deal(address(token), dria, 1 ether);
        deal(address(token), requester, 1 ether);

        // fund generators and validators
        for (uint256 i = 0; i < generators.length; i++) {
            deal(address(token), generators[i], stakes.generatorStakeAmount + stakes.validatorStakeAmount);
            assertEq(token.balanceOf(generators[i]), stakes.generatorStakeAmount + stakes.validatorStakeAmount);
        }
        for (uint256 i = 0; i < validators.length; i++) {
            deal(address(token), validators[i], stakes.validatorStakeAmount);
            assertEq(token.balanceOf(validators[i]), stakes.validatorStakeAmount);
        }
        _;
    }

    /// @dev To check if the oracles are registered
    function test_RegisterOracles() external fund deployment registerOracles {
        for (uint256 i; i < generators.length; i++) {
            assertTrue(oracleRegistry.isRegistered(generators[i], LLMOracleKind.Generator));
        }

        for (uint256 i; i < validators.length; i++) {
            assertTrue(oracleRegistry.isRegistered(validators[i], LLMOracleKind.Validator));
        }
    }

    // @notice Request without validation
    /// @dev 2 generations only
    function test_WithoutValidation()
        external
        fund
        setOracleParameters(1, 2, 0)
        deployment
        registerOracles
        safeRequest(requester, 1)
        checkAllowances
    {
        uint256 responseId;

        // try to respond as an outsider (should fail)
        uint256 dummyNonce = mineNonce(dummy, 1);
        vm.expectRevert(abi.encodeWithSelector(LLMOracleRegistry.NotRegistered.selector, dummy));
        vm.prank(dummy);
        oracleCoordinator.respond(1, dummyNonce, output, metadata);

        // respond as the first generator
        safeRespond(generators[0], output, 1);

        // verify the response
        (address _responder,,, bytes memory _output,) = oracleCoordinator.responses(1, responseId);
        assertEq(_responder, generators[0]);
        assertEq(output, _output);

        // try responding again (should fail)
        uint256 genNonce0 = mineNonce(generators[0], 1);
        vm.expectRevert(abi.encodeWithSelector(LLMOracleCoordinator.AlreadyResponded.selector, 1, generators[0]));
        vm.prank(generators[0]);
        oracleCoordinator.respond(1, genNonce0, output, metadata);

        // second responder responds
        safeRespond(generators[1], output, 1);
        responseId++;

        // verify the response
        (_responder,,, _output,) = oracleCoordinator.responses(1, responseId);
        assertEq(_responder, generators[1]);
        assertEq(output, _output);

        // try to respond after task completion (should fail)
        uint256 genNonce1 = mineNonce(generators[1], 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                LLMOracleCoordinator.InvalidTaskStatus.selector,
                1,
                uint8(LLMOracleTask.TaskStatus.Completed),
                uint8(LLMOracleTask.TaskStatus.PendingGeneration)
            )
        );
        vm.prank(generators[1]);
        oracleCoordinator.respond(1, genNonce1, output, metadata);

        // try to respond to a non-existent task (should fail)
        vm.expectRevert(
            abi.encodeWithSelector(
                LLMOracleCoordinator.InvalidTaskStatus.selector,
                900,
                uint8(LLMOracleTask.TaskStatus.None),
                uint8(LLMOracleTask.TaskStatus.PendingGeneration)
            )
        );
        vm.prank(generators[0]);
        oracleCoordinator.respond(900, genNonce0, output, metadata);
    }

    /// @notice Try to validate without being whitelisted
    ///@dev 2 generations + 2 validations
    function test_RevertWhen_ValidateWithoutWhitelist()
        external
        fund
        setOracleParameters(1, 2, 2)
        deployment
        registerOracles
        safeRequest(requester, 1)
    {
        // generators respond
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            safeRespond(generators[i], output, 1);
        }

        // set scores
        scores = [1, 5];

        // remove validator from whitelist before trying to validate
        vm.prank(dria);
        oracleRegistry.removeFromWhitelist(validators[0]);
        assertFalse(oracleRegistry.whitelisted(validators[0]));

        // try to validate without being whitelisted
        uint256 valNonce = mineNonce(validators[0], 1);
        vm.expectRevert(abi.encodeWithSelector(Whitelist.NotWhitelisted.selector, validators[0]));
        vm.prank(validators[0]);
        oracleCoordinator.validate(1, valNonce, scores, metadata);
    }

    // @notice Request with 2 generations + 2 validations
    function test_WithValidation()
        external
        fund
        setOracleParameters(1, 2, 2)
        deployment
        registerOracles
        safeRequest(requester, 1)
        addValidatorsToWhitelist
        checkAllowances
    {
        uint256 balanceBefore = token.balanceOf(dria);
        // generators respond
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            safeRespond(generators[i], output, 1);
        }

        // set scores
        scores = [15, 20];

        uint256 genNonce = mineNonce(generators[2], 1);
        // ensure third generator can't respond after completion
        vm.expectRevert(
            abi.encodeWithSelector(
                LLMOracleCoordinator.InvalidTaskStatus.selector,
                1,
                uint8(LLMOracleTask.TaskStatus.PendingValidation),
                uint8(LLMOracleTask.TaskStatus.PendingGeneration)
            )
        );
        vm.prank(generators[2]);
        oracleCoordinator.respond(1, genNonce, output, metadata);

        // validator validate
        safeValidate(validators[0], 1);

        uint256 valNonce = mineNonce(validators[0], 1);

        // ensure first validator can't validate twice
        vm.expectRevert(abi.encodeWithSelector(LLMOracleCoordinator.AlreadyResponded.selector, 1, validators[0]));
        vm.prank(validators[0]);
        oracleCoordinator.validate(1, valNonce, scores, metadata);

        // second validator validates and completes the task
        safeValidate(validators[1], 1);

        // check the task's status is Completed
        (,,, LLMOracleTask.TaskStatus status,,,,,) = oracleCoordinator.requests(1);
        assertEq(uint8(status), uint8(LLMOracleTask.TaskStatus.Completed));

        // check reponses
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            (address responder,, uint256 score, bytes memory out, bytes memory meta) = oracleCoordinator.responses(1, i);
            assertEq(responder, generators[i]);
            assertEq(out, output);
            assertEq(meta, metadata);
            assertEq(score, scores[i] * 1e18);
        }

        // withdraw platform fees
        vm.prank(dria);
        oracleCoordinator.withdrawPlatformFees();
        uint256 balanceAfter = token.balanceOf(dria);

        assertEq(balanceAfter - balanceBefore, fees.platformFee);
    }

    /// @dev Oracle cannot validate if already participated as generator
    /// @dev 1 generation + 1 validation
    function test_ValidatorIsGenerator()
        external
        fund
        setOracleParameters(1, 2, 1)
        deployment
        registerOracles
        safeRequest(requester, 1)
    {
        vm.prank(dria);
        oracleRegistry.addToWhitelist(generators);
        assertTrue(oracleRegistry.whitelisted(generators[0]));

        // register generators[0] as a validator as well
        vm.prank(generators[0]);
        oracleRegistry.register(LLMOracleKind.Validator);

        // respond as generator
        safeRespond(generators[0], output, 1);
        safeRespond(generators[1], output, 1);

        // set scores
        scores = [30, 27];

        // try to validate after responding as generator
        uint256 nonce = mineNonce(generators[0], 1);
        vm.prank(generators[0]);
        vm.expectRevert(abi.encodeWithSelector(LLMOracleCoordinator.AlreadyResponded.selector, 1, generators[0]));
        oracleCoordinator.validate(1, nonce, scores, metadata);
    }

    // @notice Request with 4 generation + 1 validation
    // @dev Not every generator gets fee
    function test_WitValidation_NotEveryGeneratorGetFee()
        external
        fund
        setOracleParameters(1, 4, 1)
        deployment
        registerOracles
        safeRequest(requester, 1)
        addValidatorsToWhitelist
    {
        uint256 balanceBefore = token.balanceOf(dria);

        uint256[] memory generatorAllowancesBefore = new uint256[](oracleParameters.numGenerations);

        // get generator allowances before function execution
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            generatorAllowancesBefore[i] = token.allowance(address(oracleCoordinator), generators[i]);
        }

        // generators respond
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            safeRespond(generators[i], output, 1);
        }

        // set scores
        // last generator doesn't get fee
        scores = [200, 140, 180, 10];

        // validator validate
        safeValidate(validators[0], 1);

        // check the task's status is Completed
        (,,, LLMOracleTask.TaskStatus status, uint256 generatorFee,,,,) = oracleCoordinator.requests(1);
        assertEq(uint8(status), uint8(LLMOracleTask.TaskStatus.Completed));

        for (uint256 i; i < oracleParameters.numGenerations; i++) {
            uint256 generatorAllowanceAfter = token.allowance(address(oracleCoordinator), generators[i]);
            // last generator doesn't get fee
            if (i == oracleParameters.numGenerations - 1) {
                assertEq(generatorAllowanceAfter - generatorAllowancesBefore[i], 0);
            } else {
                assertEq(generatorAllowanceAfter - generatorAllowancesBefore[i], generatorFee);
            }
        }

        // withdraw platform fees
        vm.prank(dria);
        oracleCoordinator.withdrawPlatformFees();

        // get balance of dria after withdraw
        uint256 balanceAfter = token.balanceOf(dria);
        // get generator fee
        (,,,, uint256 genFee,,,,) = oracleCoordinator.requests(1);
        // only 1 generator doesn't get fee
        assertEq(balanceAfter - balanceBefore, fees.platformFee + genFee);
    }
}
