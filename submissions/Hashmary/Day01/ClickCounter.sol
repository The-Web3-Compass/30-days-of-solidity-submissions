/*---------------------------------------------------------------------------
  File:   ClickCounter.sol
  Author: Marion Bohr
  Date:   04/01/2025
  Description:
    A simple counter contract to learn variable declaration, function 
    creation, and basic arithmetic. Like a YouTube view counter, tracking how
    many times a button is clicked.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ClickCounter {
    uint256 private count;

    // When incrementing or decrementing an over- or underflow 
    // can happen, at least in versions < 0.8.0
    error OverflowError();
    error UnderflowError();

    // To check count
    function getCount() external view returns (uint256) {
        return count;
    }

    // Similar to a click (with Overflow Protection)
    function increment() external {
        if (count == type(uint256).max) revert OverflowError();
           count += 1;
    }

    // Decrement by 1 (with Underflow Protection)
    function decrement() external {
        if (count == 0) revert UnderflowError();
           count -= 1;
    }

    // Initialize counter
    function reset() external {
        count = 0;
    }
}