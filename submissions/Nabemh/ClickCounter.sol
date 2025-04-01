// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ClickCounter {
    uint count = 0;

    function click() public{
        //counter increases each time the function is called
        count++;
    }

    function totalClicks() public view returns(uint){
        return count;
    }
}