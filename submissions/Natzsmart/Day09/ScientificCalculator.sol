// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ScientificCalculator {

    // Function to calculate the power of a number (base^exponent)
    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        // Anything raised to the power of 0 is 1
        if (exponent == 0) return 1;
        // Use Solidity's ** operator for exponentiation
        else return (base ** exponent);
    }

    // Function to calculate the integer square root of a number using the Babylonian method
    function squareRoot(int256 number) public pure returns (int256) {
        // Ensure the input is non-negative
        require(number >= 0, "Cannot calculate square root of negative number");

        // Square root of 0 is 0
        if (number == 0) return 0;

        // Initial guess: half of the number
        int256 result = number / 2;

        // Perform 10 iterations of the Babylonian method for approximation
        for (uint256 i = 0; i < 10; i++) {
            result = (result + number / result) / 2;
        }

        // Return the approximated square root
        return result;
    }
}