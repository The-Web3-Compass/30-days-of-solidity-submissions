// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator{
    
    function power(uint256 base,uint256 exponent)public pure returns (uint256){
        if (exponent == 0) return 1;//开次幂
        else return (base**exponent);
    }

    function squareRoot (uint256 number) public pure returns (uint256){
        require(number >=0 ,"Cannot calculate square root of negative number");//检查是不是负数
        if (number == 0) return 0;

        int256 result =int256(number) / 2;
        for (uint256 i = 0;i < 10;i++){
            result = (result + int256 (number)/result)/2;
        }
        return uint256(result);
    }
}