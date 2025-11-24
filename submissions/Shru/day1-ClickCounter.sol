// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint public counter;

    // Function to increment the counter
    function click() public {
        counter += 1;
    }
}
