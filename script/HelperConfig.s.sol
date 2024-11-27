// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {WETH9} from "../test/WETH9.sol";
import {LLMOracleTaskParameters} from "../src/LLMOracleTask.sol";

struct Stakes {
    uint256 generatorStakeAmount;
    uint256 validatorStakeAmount;
}

struct Fees {
    uint256 platformFee;
    uint256 generatorFee;
    uint256 validatorFee;
}

contract HelperConfig is Script {
    LLMOracleTaskParameters public taskParams;

    Stakes public stakes;
    Fees public fees;
    WETH9 public token;

    constructor() {
        // set deployment parameters
        stakes = Stakes({generatorStakeAmount: 0.0001 ether, validatorStakeAmount: 0.000001 ether});
        fees = Fees({platformFee: 0.0001 ether, generatorFee: 0.0001 ether, validatorFee: 0.0001 ether});
        taskParams = LLMOracleTaskParameters({difficulty: 2, numGenerations: 1, numValidations: 1, score: 0});

        // for base sepolia
        if (block.chainid == 84532) {
            // use deployed weth
            token = WETH9(payable(0x4200000000000000000000000000000000000006));
        }
        // for local create a new token
        token = new WETH9();
    }
}
