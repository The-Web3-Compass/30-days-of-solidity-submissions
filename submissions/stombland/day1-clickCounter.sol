// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract ClickCounter{

    uint256 public counter ;

    function clickInc() public 
    {
        counter ++;
    }

    function clickDec() public 
    {
        counter--;
    }
}