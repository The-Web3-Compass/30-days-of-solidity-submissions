// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

/**
 * @title ClickCounter
 * @dev Let's build a simple counter! Imagine a digital clicker. You'll create a 'function' named `click()`.
 * Each time someone calls this function, a number stored in the contract (a 'variable') will increase by one.
 * You'll learn how to declare a variable to hold a number (an `uint`) and create functions to change it (increment/decrement).
 * This is the very first step in making interactive smart contracts, showing how to store and modify data.
 * https://www.web3compass.xyz/challenge-calendar day 1
 */
contract ClickCounter {
    uint256 public counter = 0;

    function click() public {
        counter += 1;
    }

    function reset() public {
        counter = 0;
    }
}
