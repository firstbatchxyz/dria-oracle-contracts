// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Vm} from "../lib/forge-std/src/Vm.sol";
import {Upgrades} from "../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";

import {LLMOracleRegistry, LLMOracleKind} from "../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator} from "../src/LLMOracleCoordinator.sol";
import {LLMOracleTaskParameters} from "../src/LLMOracleTask.sol";

import {WETH9} from "./WETH9.sol";

abstract contract HelperTest is Test {
    struct Stakes {
        uint256 generatorStakeAmount;
        uint256 validatorStakeAmount;
    }

    struct Fees {
        uint256 platformFee;
        uint256 generationFee;
        uint256 validationFee;
    }

    struct BuyerAgentParameters {
        string name;
        string description;
        uint96 royaltyFee;
        uint256 amountPerRound;
    }

    bytes32 public constant ORACLE_PROTOCOL = "test/0.0.1";

    Stakes stakes;
    Fees fees;

    address dria;
    address[] generators;
    address[] validators;

    LLMOracleTaskParameters oracleParameters;
    LLMOracleCoordinator oracleCoordinator;
    LLMOracleRegistry oracleRegistry;

    WETH9 token;

    bytes input = "0x";
    bytes models = "0x";
    bytes metadata = "0x";

    uint256 assetPrice = 0.01 ether;
    uint256 amountPerRound = 0.015 ether;
    uint96 royaltyFee = 2;

    uint256[] scores = [1 ether, 1 ether, 1 ether];

    /// @notice The given nonce is not a valid proof-of-work.
    error InvalidNonceFromHelperTest(uint256 taskId, uint256 nonce, uint256 computedNonce, address caller);

    function setUp() public {
        dria = vm.addr(1);
        validators = [vm.addr(2), vm.addr(3), vm.addr(4)];
        generators = [vm.addr(5), vm.addr(6), vm.addr(7)];

        oracleParameters = LLMOracleTaskParameters({difficulty: 1, numGenerations: 1, numValidations: 1});

        stakes = Stakes({generatorStakeAmount: 0.01 ether, validatorStakeAmount: 0.01 ether});
        fees = Fees({platformFee: 0.0001 ether, generationFee: 0.0002 ether, validationFee: 0.00003 ether});

        vm.label(dria, "Dria");
    }

    modifier registerOracles() {
        for (uint256 i = 0; i < generators.length; i++) {
            // Approve the stake for the generator
            vm.startPrank(generators[i]);
            token.approve(address(oracleRegistry), stakes.generatorStakeAmount + stakes.validatorStakeAmount);

            // Register the generator oracle
            oracleRegistry.register(LLMOracleKind.Generator);
            vm.stopPrank();

            assertTrue(oracleRegistry.isRegistered(generators[i], LLMOracleKind.Generator));
            vm.label(generators[i], string.concat("Generator#", vm.toString(i + 1)));
        }

        for (uint256 i = 0; i < validators.length; i++) {
            // Approve the stake for the validator
            vm.startPrank(validators[i]);
            token.approve(address(oracleRegistry), stakes.validatorStakeAmount);

            // Register the validator oracle
            oracleRegistry.register(LLMOracleKind.Validator);
            vm.stopPrank();

            assertTrue(oracleRegistry.isRegistered(validators[i], LLMOracleKind.Validator));
            vm.label(validators[i], string.concat("Validator#", vm.toString(i + 1)));
        }
        _;
    }

    modifier setOracleParameters(uint8 _difficulty, uint40 _numGenerations, uint40 _numValidations) {
        oracleParameters.difficulty = _difficulty;
        oracleParameters.numGenerations = _numGenerations;
        oracleParameters.numValidations = _numValidations;

        assertEq(oracleParameters.difficulty, _difficulty);
        assertEq(oracleParameters.numGenerations, _numGenerations);
        assertEq(oracleParameters.numValidations, _numValidations);
        _;
    }

    // check generator and validator allowances before and after function execution
    // used in coordinator test
    modifier checkAllowances() {
        uint256[] memory generatorAllowancesBefore = new uint256[](oracleParameters.numGenerations);
        uint256[] memory validatorAllowancesBefore;

        // get generator allowances before function execution
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            generatorAllowancesBefore[i] = token.allowance(address(oracleCoordinator), generators[i]);
        }

        // numValidations is greater than 0
        if (oracleParameters.numValidations > 0) {
            validatorAllowancesBefore = new uint256[](oracleParameters.numValidations);
            for (uint256 i = 0; i < oracleParameters.numValidations; i++) {
                validatorAllowancesBefore[i] = token.allowance(address(oracleCoordinator), validators[i]);
            }
            // execute function
            _;

            // validator allowances after function execution
            (,,,,, uint256 valFee,,,) = oracleCoordinator.requests(1);
            for (uint256 i = 0; i < oracleParameters.numValidations; i++) {
                uint256 allowanceAfter = token.allowance(address(oracleCoordinator), validators[i]);
                assertEq(allowanceAfter - validatorAllowancesBefore[i], valFee * oracleParameters.numGenerations);
            }
        } else {
            // if no validations skip validator checks
            _;
        }

        // validate generator allowances after function execution
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            uint256 allowanceAfter = token.allowance(address(oracleCoordinator), generators[i]);
            (,,,, uint256 expectedIncrease,,,,) = oracleCoordinator.requests(1);
            assertEq(allowanceAfter - generatorAllowancesBefore[i], expectedIncrease);
        }
    }

    // Mines a valid nonce until the hash meets the difficulty target
    function mineNonce(address responder, uint256 taskId) internal view returns (uint256) {
        // get the task
        (address requester,,,,,,,,) = oracleCoordinator.requests(taskId);
        uint256 target = type(uint256).max >> oracleParameters.difficulty;

        uint nonce = 0;
        for (; nonce < type(uint256).max; nonce++) {
            bytes memory message = abi.encodePacked(taskId, input, requester, responder, nonce);
            uint256 digest = uint256(keccak256(message));

            if (uint256(digest) < target) {
                break;
            }
        }

        return nonce;
    }

    modifier safeRequest(address requester, uint256 taskId) {
        (uint256 _total, uint256 _generator, uint256 _validator) = oracleCoordinator.getFee(oracleParameters);

        vm.startPrank(requester); // simulate transaction from requester
        token.approve(address(oracleCoordinator), _total);
        oracleCoordinator.request(ORACLE_PROTOCOL, input, models, oracleParameters);
        vm.stopPrank();

        // check request params
        (
            address _requester,
            ,
            ,
            ,
            uint256 _generatorFee,
            uint256 _validatorFee,
            ,
            bytes memory _input,
            bytes memory _models
        ) = oracleCoordinator.requests(taskId);

        assertEq(_requester, requester);
        assertEq(_input, input);
        assertEq(_models, models);
        assertEq(_generatorFee, _generator);
        assertEq(_validatorFee, _validator);
        _;
    }

    function safeRespond(address responder, bytes memory output, uint256 taskId) internal {
        uint256 nonce = mineNonce(responder, taskId);
        vm.prank(responder);
        oracleCoordinator.respond(taskId, nonce, output, metadata);
    }

    function safeValidate(address validator, uint256 taskId) internal {
        uint256 nonce = mineNonce(validator, taskId);
        vm.prank(validator);
        oracleCoordinator.validate(taskId, nonce, scores, metadata);
    }

}
