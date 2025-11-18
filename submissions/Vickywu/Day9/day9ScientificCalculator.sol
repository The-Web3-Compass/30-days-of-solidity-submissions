//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ScientificCalculator{

    //用于计算幂的函数
    function power(uint256 base, uint256 exponent)public pure returns(uint256){  //被标记为 pure，因为它不读取或更改区块链上的任何内容。它只是进行数学运算。
        if(exponent == 0)return 1; //如果指数为0，它返回1——这只是标准数学
        else return (base ** exponent);
    }

    //估算平方根
    function squareRoot(int256 number)public pure returns(int256){
        require(number >= 0, "Cannot calculate square root of negative number");  //使用 require 检查输入的数字是否为负数
        if(number == 0)return 0;  //处理一个快速的特殊情况：如果这个数是0，那么它的平方根也是0——所以我们会立即返回这个结果

        int256 result = number/2;  //将数字除以二开始进行粗略估计
        for(uint256 i = 0; i<10; i++){  //使用一个简单的公式将那个猜测值进行十次精炼
            result = (result + number / result)/2;  //这个公式通过结合当前的猜测值与如果猜测值完美时我们得到的结果，并将它们取平均值来工作。每次循环都使我们可以更接近实际的平方根。
        }

        return result;

    }
}