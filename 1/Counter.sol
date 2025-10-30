// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint public count; // state variable to store number

    // Function to increment count
    function click() public {
        count += 1;
    }

    // Function to decrement count
    function undo() public {
        require(count > 0, "Count cannot go below zero");
        count -= 1;
    }

    // Function to read current count (optional since `count` is public)
    function getCount() public view returns (uint) {
        return count;
    }
}
