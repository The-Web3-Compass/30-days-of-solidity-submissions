// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract clickCounter{
    uint public counter;

    function click() external {
         counter++;
    }

    function increment() external {
         counter ++;
    }

    function decrement() external {
        counter--;
    }
}