// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// CHALLENGE
// Let's build a simple counter! Imagine a digital clicker. You'll create a 'function' named `click()`. 
// Each time someone calls this function, a number stored in the contract (a 'variable') will increase by one. 
// You'll learn how to declare a variable to hold a number (an `uint`) and create functions to change it (increment/decrement). 
// This is the very first step in making interactive smart contracts, showing how to store and modify data.


contract clickCounter {
    
    // track the number of clicks done by a user.
    uint8 public clickCount = 0;

    function click() public {
        clickCount++;
    }


}