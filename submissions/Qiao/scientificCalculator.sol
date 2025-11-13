// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator {

     function squareRoot(uint256 a) public pure returns (uint256) {
        require(a > 0, "Positive number required.");
        uint256 x = a;
        uint256 y = (x + 1) / 2;
        while (y < x) {
            x = y;
            y = (x + a / x) / 2;
        }
        return x;
    }

    function power(uint256 base, uint256 exp) public pure returns (uint256) {
        if(exp == 0) return 1;
        return base ** exp;
    }
}