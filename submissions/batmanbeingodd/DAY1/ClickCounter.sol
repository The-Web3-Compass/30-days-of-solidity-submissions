//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract Counter{
    uint public count;

    function clickIncrement() public{
        count=count+1;

    }
    function clickdecrement() public{
        count= count-1;
        
    }
}
