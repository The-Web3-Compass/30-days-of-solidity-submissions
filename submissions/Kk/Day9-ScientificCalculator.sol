// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator {
    // advanced functions will go here

    //power(base, exponent), pure means it's a pure calculate function.
    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) 
            return 1;
        else 
            return (base ** exponent);
    }

    //squareRoot(number)
    function squareRoot (int256 number) public pure returns (int256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        if (number == 0)
            return 0;

        int256 result = number / 2;
        for (uint256 i = 0; i < 10; i++){
            result = (result + number / result) / 2;
        }
        return
            result;
    }
}

