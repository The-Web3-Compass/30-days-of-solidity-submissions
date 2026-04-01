// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ClickCounter {
    uint public count = 0;

    function increment() public {
        count++;
    }

    function decrement() public {
        count--;
    }

    function getCount() public view returns (uint) {
        return count;
    }
}
