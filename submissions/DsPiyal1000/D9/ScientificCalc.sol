// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ScientificCalculator {
    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) return 1;
        return base ** exponent;
    }

    function squareRoot(uint256 number) public pure returns (uint256) {
        require(number >= 0, "Value must be non-negative!");
        if (number == 0) return 0;
        if (number == 1) return 1;

        uint256 result = number / 2;
        uint256 prevResult;
        
        for (uint256 i = 0; i < 10; i++) {
            prevResult = result;
            result = (result + number / result) / 2;
            
            if (result == prevResult || result + 1 == prevResult || result == prevResult + 1) {
                break;
            }
        }
        return result;
    }
}