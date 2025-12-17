// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator{
    // 幂运算
    function power(uint256 base, uint256 exponent) public pure returns (uint256){
        if (exponent == 0) {
            return 1;
        } else {
            return base ** exponent;
        }
    }
    // 平方根运算(近似)
    function sqrt(int256 num) public pure returns (int256){
        require(num >= 0, "Cannot calculate square root of negative number");
        if (num == 0) {
            return 0;
        } else {
            int256 result = num / 2;
            for (uint256 i = 0; i < 10; i++) {
                result = (result + num / result)/2;
            }
            return result;
        }
    }
}