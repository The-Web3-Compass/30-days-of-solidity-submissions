// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error ClickCounter__AlreadyZero();

contract ClickCounter {
    uint256 public counter;

    function increaseCounter() external {
        counter++;
    }

    function decreaseCounter() external {
        if (counter == 0) revert ClickCounter__AlreadyZero();
        counter--;
    }

    function resetCounter() external {
        counter = 0;
    }

    function getCounterValue() external view returns (uint256) {
        return counter;
    }
}
