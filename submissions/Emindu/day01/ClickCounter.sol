// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalClicker {
    
    uint public count;

    event CounterChanged(uint newCount, address indexed changedBy);

    function click() external {
        count += 1;
        emit CounterChanged(count, msg.sender);
    }

    function decrement() external {
        require(count > 0, "The clicker cannot go below zero.");
        count -= 1;
        emit CounterChanged(count, msg.sender);
    }
}
