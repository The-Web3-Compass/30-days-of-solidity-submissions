// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StatisticsCalculator {
    // Calculates the mean (average) of an array of numbers
    function calculateMean(uint256[] memory numbers) public pure returns (uint256) {
        require(numbers.length > 0, "Array cannot be empty");

        uint256 sum = 0;
        for(uint i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }

        return sum / numbers.length;
    }
}
