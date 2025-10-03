// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ClickCounter {
    uint256 public a;

    function increment() public {
        a++;
    }

    function decrement() public {
        require(a>0,"Not possible decrement!");
        a--;
    }
}