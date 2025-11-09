//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator {
    // Exponentiation: base ** exponent
    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) return 1;
        return (base ** exponent);
    }

    // Integer square root approximation via Newton's Method
    function squareRoot(uint256 number) public pure returns (uint256) {
        if (number == 0) return 0;

        uint256 result = number / 2 + 1; // initial guess (avoid division by zero)
        uint256 prev;
        
        // Iterate until convergence or a reasonable gap
        for (uint256 i = 0; i < 50; i++) {
            prev = result;
            result = (result + number / result) / 2;
            if (result >= prev) break; // converged (monotonic non increasing)
        }
        // Ensure floor behavior (result^2 <= number) 
        while (result * result > number) {
            result--;
        }
        return result;
    }
}