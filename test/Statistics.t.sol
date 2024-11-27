// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";
import {Statistics} from "../src/Statistics.sol";

contract StatisticsTest is Test {
    uint8 constant UINT8_MAX = type(uint8).max;
    uint8 constant UINT8_MIN = type(uint8).min;
    function testFuzz_Average(uint8 number1, uint8 number2, uint8 number3, uint8 number4) external pure {
        vm.assume(number1 <= UINT8_MAX && number1 >= UINT8_MIN);
        vm.assume(number2 <= UINT8_MAX && number2 >= UINT8_MIN);
        vm.assume(number3 <= UINT8_MAX && number3 >= UINT8_MIN);
        vm.assume(number4 <= UINT8_MAX && number4 >= UINT8_MIN);

        uint256[] memory data = new uint256[](4);
        data[0] = number1;
        data[1] = number2;
        data[2] = number3;
        data[3] = number4;

        uint256 average = Statistics.avg(data);
        console.log("Average: ", average);
    }

    function testFuzz_Variance(uint8 number1, uint8 number2, uint8 number3, uint8 number4, uint8 number5)
        external
        pure
    {
        vm.assume(number1 <= UINT8_MAX && number1 >= UINT8_MIN);
        vm.assume(number2 <= UINT8_MAX && number2 >= UINT8_MIN);
        vm.assume(number3 <= UINT8_MAX && number3 >= UINT8_MIN);
        vm.assume(number4 <= UINT8_MAX && number4 >= UINT8_MIN);
        vm.assume(number5 <= UINT8_MAX && number5 >= UINT8_MIN);

        uint256[] memory data = new uint256[](5);
        data[0] = number1;
        data[1] = number2;
        data[2] = number3;
        data[3] = number4;
        data[4] = number5;

        (uint256 variance,) = Statistics.variance(data);
        console.log("Variance: ", variance);
    }

    function testFuzz_StandardDeviation(
        uint8 number1,
        uint8 number2,
        uint8 number3,
        uint8 number4,
        uint8 number5,
        uint8 number6,
        uint8 number7,
        uint8 number8,
        uint8 number9,
        uint8 number10
    ) external pure {
        vm.assume(number1 <= UINT8_MAX && number1 > UINT8_MIN);
        vm.assume(number2 <= UINT8_MAX && number2 > UINT8_MIN);
        vm.assume(number3 <= UINT8_MAX && number3 > UINT8_MIN);
        vm.assume(number4 <= UINT8_MAX && number4 > UINT8_MIN);
        vm.assume(number5 <= UINT8_MAX && number5 > UINT8_MIN);
        vm.assume(number6 <= UINT8_MAX && number6 > UINT8_MIN);
        vm.assume(number7 <= UINT8_MAX && number7 > UINT8_MIN);
        vm.assume(number8 <= UINT8_MAX && number8 > UINT8_MIN);
        vm.assume(number9 <= UINT8_MAX && number9 > UINT8_MIN);
        vm.assume(number10 <= UINT8_MAX && number10 > UINT8_MIN);

        uint256[] memory data = new uint256[](10);
        data[0] = number1;
        data[1] = number2;
        data[2] = number3;
        data[3] = number4;
        data[4] = number5;
        data[5] = number6;
        data[6] = number7;
        data[7] = number8;
        data[8] = number9;
        data[9] = number10;

        (uint256 stddev,) = Statistics.stddev(data);
        console.log("Standard Deviation: ", stddev);
    }
}
