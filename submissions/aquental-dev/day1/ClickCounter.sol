// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    //count is public variable to ease testing
    uint256 public count;

    // Function to increment counter by 1
    function click() public {
        count += 1;
    }

    // Function to increment counter by 1
    function increment() public {
        count += 1;
    }

    // Function to decrement counter by 1
    function decrement() public {
        require(count > 0, "Counter cannot be negative");
        count -= 1;
    }
}
