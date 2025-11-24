// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract ClickCounter{

    uint256 public counter;
    address public owner; //记录合约拥有者

constructor() {
    owner = msg.sender; //合约是谁发起的，谁就是owner
}

//增加计数
function click() public{
    counter++; 
}

//减少计数
function decrement() public{
    counter--;
}

//重置计数
function reset() public{
    require(msg.sender == owner);
    counter = 0 ;
}
}
