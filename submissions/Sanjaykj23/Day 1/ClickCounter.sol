// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract ClickCounter{
    uint private count=0;
    function display() public view returns (uint){
        return count;
    }
    function increment()public{
        count++;
    }
}