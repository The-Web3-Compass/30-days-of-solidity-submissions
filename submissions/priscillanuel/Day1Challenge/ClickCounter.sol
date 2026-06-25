// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract ClickCounter {
    uint256 public counter;

    function click() public {
        counter ++;
    }

    function decrement() public {
        counter --;
    } 

}
