//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ClickCounter
 * @dev A simple contract that counts the number of times a button is clicked.
 */
contract ClickCounter {
    uint256 public clickCount; // State variable to store the click count

    // Increment the click count by 1
    function clickIncrement() public {
        clickCount++;
    }

    // Decrement the click count by 1
    function clickDecrement() public {
        require(clickCount > 0, "Click count cannot be negative");
        clickCount--;
    }

    // Reset the click count to 0
    function resetCount() public {
        clickCount = 0;
    }
}