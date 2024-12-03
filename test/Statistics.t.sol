// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";
import {Statistics} from "../src/Statistics.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract StatisticsTest is Test {
    uint8 constant MAX_SCORE = 255; // max value of uint8
    uint8 constant MIN_SCORE = 1;

    struct TestData {
        uint256 average;
        uint256 variance;
        uint256 stddev;
    }

    uint256[] scores1 = new uint8[](9);
    uint256[] scores2 = new uint8[](9);
    uint256[] scores3 = new uint8[](9);
    uint256[] scores5 = new uint8[](9);
    uint256[] scores4 = new uint8[](9);

    TestData data1 = TestData(251 ether, 6.666666666666666666 ether, 2.581988897 ether);
    TestData data2 = TestData(255 ether, 0 ether, 0 ether);
    TestData data3 = TestData(73 ether, 1500 ether, 38.7298334621 ether);
    TestData data4 = TestData(1 ether, 0 ether, 0 ether);
    TestData data5 = TestData(171 ether, 2406.666666666666666666 ether, 49.057789052 ether);

    function setUp() public {
        for (uint256 i; i < 9; i++) {
            scores1[i] = MAX_SCORE - i; // 255, 254, 253, 252, 251, 250, 249, 248, 247
            scores2[i] = MAX_SCORE; // 255, 255, 255, ..., 255
            scores3[i] = 15 * i + 13; // 13, 28, 43, 58, 73, 88, 103, 118, 133
            scores4[i] = 1; // 1, 1, 1
            scores5[i] = 19 * (i + 5); // 95, 114, 133, 152, 171, 190, 209, 228, 247
        }

        vm.label(address(this), "StatisticsTest");
    }

    // 0 tolerance for average
    function test_Average() external view {
        uint256 average1 = Statistics.avg(scores1);
        vm.assertApproxEqAbs(average1, data1.average, 0);

        uint256 average2 = Statistics.avg(scores2);
        vm.assertApproxEqAbs(average2, data2.average, 0);

        uint256 average3 = Statistics.avg(scores3);
        vm.assertApproxEqAbs(average3, data3.average, 0);

        uint256 average4 = Statistics.avg(scores4);
        vm.assertApproxEqAbs(average4, data4.average, 0);

        uint256 average5 = Statistics.avg(scores5);
        vm.assertApproxEqAbs(average5, data5.average, 0);
    }

    // 0 tolerance for variance
    function test_Variance() external view {
        (uint256 variance1,) = Statistics.variance(scores1);
        vm.assertApproxEqAbs(variance1, data1.variance, 0);

        (uint256 variance2,) = Statistics.variance(scores2);
        vm.assertApproxEqAbs(variance2, data2.variance, 0);

        (uint256 variance3,) = Statistics.variance(scores3);
        vm.assertApproxEqAbs(variance3, data3.variance, 0);

        (uint256 variance4,) = Statistics.variance(scores4);
        vm.assertApproxEqAbs(variance4, data4.variance, 0);

        (uint256 variance5,) = Statistics.variance(scores5);
        vm.assertApproxEqAbs(variance5, data5.variance, 0);
    }

    // 0.000001% tolerance for standard deviation
    function test_StandardDeviation() external view {
        /// Compares two `uint256` values. Expects relative difference in percents to be less than or equal to `maxPercentDelta`.
        /// `maxPercentDelta` is an 18 decimal fixed point number, where 1e18 == 100%
        /// Formats values with decimals in failure message.
        // assertApproxEqRelDecimal(uint256 left, uint256 right, uint256 maxPercentDelta, uint256 decimals)
        (uint256 stddev1,) = Statistics.stddev(scores1);
        vm.assertApproxEqRelDecimal(stddev1, data1.stddev, 1e10, 18);

        (uint256 stddev2,) = Statistics.stddev(scores2);
        vm.assertApproxEqRelDecimal(stddev2, data2.stddev, 1e10, 18);

        (uint256 stddev3,) = Statistics.stddev(scores3);
        vm.assertApproxEqRelDecimal(stddev3, data3.stddev, 1e10, 18);

        (uint256 stddev4,) = Statistics.stddev(scores4);
        vm.assertApproxEqRelDecimal(stddev4, data4.stddev, 1e10, 18);

        (uint256 stddev5,) = Statistics.stddev(scores5);
        vm.assertApproxEqRelDecimal(stddev5, data5.stddev, 1e10, 18);
    }

    function testFuzz_Average(uint8 number1, uint8 number2, uint8 number3, uint8 number4) external pure {
        vm.assume(number1 <= MAX_SCORE && number1 >= MIN_SCORE);
        vm.assume(number2 <= MAX_SCORE && number2 >= MIN_SCORE);
        vm.assume(number3 <= MAX_SCORE && number3 >= MIN_SCORE);
        vm.assume(number4 <= MAX_SCORE && number4 >= MIN_SCORE);

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
        vm.assume(number1 <= MAX_SCORE && number1 >= MIN_SCORE);
        vm.assume(number2 <= MAX_SCORE && number2 >= MIN_SCORE);
        vm.assume(number3 <= MAX_SCORE && number3 >= MIN_SCORE);
        vm.assume(number4 <= MAX_SCORE && number4 >= MIN_SCORE);
        vm.assume(number5 <= MAX_SCORE && number5 >= MIN_SCORE);

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
        vm.assume(number1 <= MAX_SCORE && number1 > MIN_SCORE);
        vm.assume(number2 <= MAX_SCORE && number2 > MIN_SCORE);
        vm.assume(number3 <= MAX_SCORE && number3 > MIN_SCORE);
        vm.assume(number4 <= MAX_SCORE && number4 > MIN_SCORE);
        vm.assume(number5 <= MAX_SCORE && number5 > MIN_SCORE);
        vm.assume(number6 <= MAX_SCORE && number6 > MIN_SCORE);
        vm.assume(number7 <= MAX_SCORE && number7 > MIN_SCORE);
        vm.assume(number8 <= MAX_SCORE && number8 > MIN_SCORE);
        vm.assume(number9 <= MAX_SCORE && number9 > MIN_SCORE);
        vm.assume(number10 <= MAX_SCORE && number10 > MIN_SCORE);

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
