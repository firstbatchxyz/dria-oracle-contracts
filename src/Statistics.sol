// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";

/// @notice Simple statistic library for uint256 arrays.
library Statistics {
    uint256 constant SCALING_FACTOR = 1e18;

    /// @notice Compute the mean of the data.
    /// @param data The data to compute the mean for.
    function avg(uint256[] memory data) internal pure returns (uint256 ans) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, uint256 newSum) = Math.tryAdd(data[i], sum);
            require(success);
            sum = newSum;
        }
        ans = Math.mulDiv(sum, SCALING_FACTOR, data.length);
    }

    /// @notice Compute the variance of the data.
    /// @param data The data to compute the variance for.
    function variance(uint256[] memory data) internal pure returns (uint256 ans, uint256 mean) {
        mean = Statistics.avg(data);

        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            uint256 scaledData = data[i] * SCALING_FACTOR; // scale the data point to match the scaled mean
            int256 diff = int256(scaledData) - int256(mean);
            sum += uint256(SignedMath.abs(diff * diff));
        }
        (, uint256 divisor) = Math.tryMul(data.length, SCALING_FACTOR);
        ans = Math.mulDiv(sum, 1, divisor);
    }

    /// @notice Compute the standard deviation of the data.
    /// @dev Computes variance, and takes the square root.
    /// @param data The data to compute the standard deviation for.
    function stddev(uint256[] memory data) internal pure returns (uint256 ans, uint256 mean) {
        (uint256 _variance, uint256 _mean) = Statistics.variance(data);
        mean = _mean;
        (bool success, uint256 scaledVariance) = Math.tryMul(_variance, SCALING_FACTOR);
        require(success);
        ans = Math.sqrt(scaledVariance);
    }
}
