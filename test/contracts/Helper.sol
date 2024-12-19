// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";

import {LLMOracleRegistry, LLMOracleKind} from "../../src/LLMOracleRegistry.sol";
import {LLMOracleCoordinator} from "../../src/LLMOracleCoordinator.sol";
import {LLMOracleTaskParameters} from "../../src/LLMOracleTask.sol";

import {WETH9} from "./WETH9.sol";

/// @notice CREATED TO PREVENT CODE DUPLICATION IN TESTS
abstract contract Helper is Test {
    struct Stakes {
        uint256 generator;
        uint256 validator;
    }

    struct Fees {
        uint256 platform;
        uint256 generation;
        uint256 validation;
    }

    /*//////////////////////////////////////////////////////////////
                             STORAGE
    //////////////////////////////////////////////////////////////*/

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

    uint256[] scores = [1, 1, 1];

    uint256 public minRegistrationTime = 1 days; // in seconds
    uint256 public minScore = 1;
    uint256 public maxScore = type(uint8).max; // 255

    function setUp() public {
        // define parameters for tests
        dria = vm.addr(1);
        validators = [vm.addr(2), vm.addr(3), vm.addr(4)];
        generators = [vm.addr(5), vm.addr(6), vm.addr(7), vm.addr(8)];

        oracleParameters = LLMOracleTaskParameters({difficulty: 1, numGenerations: 1, numValidations: 1});

        stakes = Stakes({generator: 0.01 ether, validator: 0.01 ether});
        fees = Fees({platform: 0.0001 ether, generation: 0.0002 ether, validation: 0.00003 ether});

        vm.label(dria, "Dria");
    }

    /*//////////////////////////////////////////////////////////////
                             MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Add validators to the whitelist.
    modifier addValidatorsToWhitelist() {
        vm.prank(dria);
        oracleRegistry.addToWhitelist(validators);

        for (uint256 i; i < validators.length; i++) {
            vm.assertTrue(oracleRegistry.isWhitelisted(validators[i]));
        }
        _;
    }

    /// @notice Register the oracles & label them like Generator#1, Validator#1, etc.
    /// @dev Used in coordinator tests
    modifier registerOracles() {
        for (uint256 i = 0; i < generators.length; i++) {
            // approve the generatorStakeAmount for the generator
            vm.startPrank(generators[i]);
            token.approve(address(oracleRegistry), stakes.generator + stakes.validator);

            // register the generator oracle
            oracleRegistry.register(LLMOracleKind.Generator);
            vm.stopPrank();

            // check if the generator is registered
            assertTrue(oracleRegistry.isRegistered(generators[i], LLMOracleKind.Generator));
            // label generator address
            vm.label(generators[i], string.concat("Generator#", vm.toString(i + 1)));
        }

        // add validators to whitelist if not already added
        vm.prank(dria);
        oracleRegistry.addToWhitelist(validators);

        for (uint256 i = 0; i < validators.length; i++) {
            assertTrue(oracleRegistry.isWhitelisted(validators[i]));
            // approve the validatorStakeAmount for the validator
            vm.startPrank(validators[i]);
            token.approve(address(oracleRegistry), stakes.validator);

            // register the validator oracle
            oracleRegistry.register(LLMOracleKind.Validator);
            vm.stopPrank();

            // check if the validator is registered & label validator address
            assertTrue(oracleRegistry.isRegistered(validators[i], LLMOracleKind.Validator));
            vm.label(validators[i], string.concat("Validator#", vm.toString(i + 1)));
        }
        _;
    }

    /// @notice Set oracle parameters
    /// @dev Used in coordinator tests
    modifier setOracleParameters(uint8 _difficulty, uint40 _numGenerations, uint40 _numValidations) {
        oracleParameters.difficulty = _difficulty;
        oracleParameters.numGenerations = _numGenerations;
        oracleParameters.numValidations = _numValidations;
        _;
    }

    /// @notice Check generator and validator allowances before and after function execution
    /// @dev Used only for NON-REVERTED functions in coordinator tests
    /// @dev Request must be made in the function that uses this modifier
    modifier checkAllowances() {
        uint256[] memory generatorAllowancesBefore = new uint256[](oracleParameters.numGenerations);
        uint256[] memory validatorAllowancesBefore = new uint256[](oracleParameters.numValidations);

        // get generator allowances before function execution
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            generatorAllowancesBefore[i] = token.allowance(address(oracleCoordinator), generators[i]);
        }

        // get validator allowances before function execution
        for (uint256 i = 0; i < oracleParameters.numValidations; i++) {
            validatorAllowancesBefore[i] = token.allowance(address(oracleCoordinator), validators[i]);
        }

        // execute function
        _;

        (,,,, uint256 generatorFee, uint256 validatorFee,,,) = oracleCoordinator.requests(1);
        // check generator allowances after function execution
        // when scores are same all generators get generator fee
        for (uint256 i = 0; i < oracleParameters.numGenerations; i++) {
            uint256 generatorAllowanceAfter = token.allowance(address(oracleCoordinator), generators[i]);
            assertEq(generatorAllowanceAfter - generatorAllowancesBefore[i], generatorFee);
        }

        // check validator allowances after function execution if numValidations is greater than 0
        // validator allowances after function execution
        for (uint256 i = 0; i < oracleParameters.numValidations; i++) {
            uint256 validatorAllowanceAfter = token.allowance(address(oracleCoordinator), validators[i]);
            assertEq(
                validatorAllowanceAfter - validatorAllowancesBefore[i], validatorFee * oracleParameters.numGenerations
            );
        }
    }

    /// @notice Make a request to the oracle coordinator
    /// @dev Used in coordinator tests
    modifier safeRequest(address requester, uint256 taskId) {
        (uint256 _total, uint256 _generator, uint256 _validator) = oracleCoordinator.getFee(oracleParameters);

        vm.startPrank(requester);
        // approve coordinator
        token.approve(address(oracleCoordinator), _total);
        // make a request
        oracleCoordinator.request(ORACLE_PROTOCOL, input, models, oracleParameters);
        vm.stopPrank();

        // check the request is valid
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

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mines a valid nonce until the hash meets the difficulty target
    /// @param responder The responder address
    /// @param taskId The task id
    /// @return nonce The valid nonce
    /// @dev Used in coordinator tests
    function mineNonce(address responder, uint256 taskId) internal view returns (uint256) {
        // get the task
        (address requester,,,,,,,,) = oracleCoordinator.requests(taskId);
        uint256 target = type(uint256).max >> oracleParameters.difficulty;

        uint256 nonce = 0;
        for (; nonce < type(uint256).max; nonce++) {
            bytes memory message = abi.encodePacked(taskId, input, requester, responder, nonce);
            uint256 digest = uint256(keccak256(message));

            if (uint256(digest) < target) {
                break;
            }
        }

        return nonce;
    }

    /// @notice Responds to task
    /// @param responder The responder address
    /// @param output The output data
    /// @param taskId The task id
    function safeRespond(address responder, bytes memory output, uint256 taskId) internal {
        uint256 nonce = mineNonce(responder, taskId);
        vm.prank(responder);
        oracleCoordinator.respond(taskId, nonce, output, metadata);
    }

    /// @notice Validates a task
    /// @param validator Validator address
    /// @param taskId Task id
    function safeValidate(address validator, uint256 taskId) internal {
        uint256 nonce = mineNonce(validator, taskId);
        vm.prank(validator);
        oracleCoordinator.validate(taskId, nonce, scores, metadata);
    }
}
