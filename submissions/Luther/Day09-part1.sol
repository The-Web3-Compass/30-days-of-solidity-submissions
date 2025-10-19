//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ScientificCalculator{

function power(uint256 base,uint256 exponent) public pure returns(uint256){     //定义一个对整数进行幂次方计算的函数
    if(exponent == 0)return 1;     //判断指数是否为0，如果是则返回1
    else return (base ** exponent);     //如果指数不为 0，则返回底数的幂
}

function squareRoot(int256 number)public pure returns(int256){     //定义一个计算整数平方根的函数
    require(number >= 0, "Cannot calculate squareroot of negative number");     //检查输入是否为非负数,否则报错
    if(number == 0)return 0;     //如果输入为 0，直接返回 0

    int256 result = number/2;    //定义并初始化变量 result 为输入的一半
    for(uint256 i = 0; i<10; i++){     //执行一个循环，共运行 10 次
        result = (result +number / result)/2;     //执行一次牛顿迭代公式
    }

return result;     //返回计算得到的平方根近似值

}


}