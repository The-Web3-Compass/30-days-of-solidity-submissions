//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
//编译器版本
contract ClickCounter{
//定义一个名为ClickCounter的智能合约
uint256 public counter;
//声明一个公开无符号256位整数变量counter
function click() public {
    counter++;
}
//定义一个公共函数click()。每次调用时,将counter的值加1。
//++是递增运算符,等同于counter = counter + 1
function clickMultiple(uint256 times) public {
    counter += times;
}
//一次增加多次，+=加并赋值
function decrease() public {
    counter = counter -1;
}
//减少一次
function reset() public {
    counter = 0;
}
//将计数器重置为0
function getCounter() public view returns (uint256){
    return counter + 100;
}

}