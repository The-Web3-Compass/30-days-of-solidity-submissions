// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator {
    
    //幂函数
    function power(uint256 base, uint exponent) public pure returns (uint256) {
        if(exponent == 0) return 1;
        else return (base ** exponent);

    }

    //平方根
    function squareRoot(uint256 number) public pure returns (uint256) {
        require(number >= 0, "cannot calculate square root of negative number");
        if(number == 0) return 0;

        int256 result = number / 2;
        for(uint256 i = 0; i < 10; i++){
            result = (result + number / result ) / 2;

        }
        return result;

    }

    

}