// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";

/// @notice Simple statistic library for uint256 arrays, numbers are treat as fixed-precision floats.
library Statistics {
    /// @notice Compute the mean of the data.
    /// @param data The data to compute the mean for.
    function avg(uint256[] memory data) internal pure returns (uint256 ans) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        // sum * 1 / data.length 
        ans = Math.mulDiv(sum, 1, data.length);
    }

    /// @notice Compute the variance of the data.
    /// @param data The data to compute the variance for.
    function variance(uint256[] memory data) internal pure returns (uint256 ans, uint256 mean) {
        mean = avg(data);
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            int256 diff = int256(data[i]) - int256(mean);
            // abs return the result as uint256
            sum += SignedMath.abs(diff * diff);
        }
        ans = Math.mulDiv(sum, 1, data.length);
    }

    /// @notice Compute the standard deviation of the data.
    /// @dev Computes variance, and takes the square root.
    /// @param data The data to compute the standard deviation for.
    function stddev(uint256[] memory data) internal pure returns (uint256 ans, uint256 mean) {
        (uint256 _variance, uint256 _mean) = variance(data);
        mean = _mean;
        ans = Math.sqrt(_variance);
    }
}
