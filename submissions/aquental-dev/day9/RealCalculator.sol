// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract that performs actual mathematical calculations
contract RealCalculator {
    // Performs addition of two numbers
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    // Performs subtraction, ensures result doesn't underflow
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "Subtraction would result in negative number");
        return a - b;
    }

    // Performs multiplication of two numbers
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }

    // Performs division, checks for division by zero
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Division by zero");
        return a / b;
    }

    // Calculates base raised to the power of exponent
    function power(
        uint256 base,
        uint256 exponent
    ) public pure returns (uint256) {
        return base ** exponent;
    }

    // Calculates the nth root of a number
    function root(uint256 a, uint256 n) public pure returns (uint256) {
        require(n > 0, "Root index must be greater than zero");
        if (a == 0) return 0;

        uint256 result = 1;
        uint256 delta;
        uint256 temp; // Declare temp variable

        // Newton's method for nth root
        do {
            temp = result; // Assign result to temp
            delta = (a / power(result, n - 1) - result) / n;
            result = result + delta;
        } while (delta > 1 && result != temp);

        return result;
    }
}
