// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ScientificCalculator {
    function power(uint _base, uint _exponent) public pure returns (uint) {
        if (_exponent == 0) return 1;
        return (_base ** _exponent);
    }

    function squareRoot(uint256 number) public pure returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        if (number == 0) return 0;
        // newton's method 
        uint256 result = number;
        for (uint256 i = 0; i < 10; i++) {
            result = (result + number / result) / 2;
        }
        return result;
    }
}
