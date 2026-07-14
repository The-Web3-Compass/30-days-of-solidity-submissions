// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleCounter {
    uint public counter;
    constructor() {
        counter = 0;
    }
    function click() public {
        counter = counter + 1;
    }
    function decrement() public {
        require(counter > 0, "Counter cannot go below zero");
        counter = counter - 1;
    }
    function getCounter() public view returns (uint) {
        return counter;
    }
    function reset() public {
        counter = 0;
    }
}