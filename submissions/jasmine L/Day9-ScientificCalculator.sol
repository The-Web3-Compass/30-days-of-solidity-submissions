// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator{
    // 高级运算

    // 幂计算
    function power(uint256 base, uint256 exponent) public pure returns(uint256){
        // 是否会存在溢出问题呢？
        // pure 不读取或更改区块链上的任何内容。只是进行数学运算
         return base ** exponent;
    }


    // 计算平方根
    function square(uint256 base) public pure returns(uint256){
        // 存在这个除数除不尽（需要对结果进行解释），如果是负数也不太好
        // 什么时候需要写memory呢？为什么数字不需要写？是不需要内存吗？
        require(base>=0, " Invaild number!");
        
        uint256 result = base/2;
        for (int i =0; i<10; i++) 
        {
            result = (result + base/result )/2;
        }
        return result;
    }

}