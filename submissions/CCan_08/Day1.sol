// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract Clickconter{
    uint256 public counter;
    uint256 private  operationCount;
function click() public {
    counter ++;
    operationCount ++;
} 
//增加计数器
function decrease() public {
     if (counter > 0) {
           counter --;
    operationCount ++;
}
}
//增加减数
function reset() public{

    counter = 0;
    operationCount ++;
}
//增加重置
function ClickMultipl(uint256 times) public {
require(times>0,"Times must be greater than 0");
counter += times;
operationCount ++;
}

function GetCounter() public view returns (uint256) {
return operationCount;
}
//增加操作计数器
}