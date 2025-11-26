// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ClickCounter{
    uint public count = 0;

    function click() public {
        count+=1;
    }

    function decrement() public {
        if(count != 0){
            count-=1;
        }
    }
}