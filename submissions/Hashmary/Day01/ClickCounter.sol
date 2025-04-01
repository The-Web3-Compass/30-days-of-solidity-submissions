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

/// @title Simple Counter Contract
contract ClickCounter {
    uint256 private _count;

    // Custom Errors (gas-efficient)
    error OverflowError();
    error UnderflowError();

    /// @notice current count
    function getCount() external view returns (uint256) {
        return _count;
    }

    /// @notice Similar to a click (with Overflow Protection)
    function increment() external {
        if (_count == type(uint256).max) revert OverflowError();
        _count += 1;
    }

    /// @notice Decrement by 1 (with Underflow Protection)
    function decrement() external {
        if (_count == 0) revert UnderflowError();
        _count -= 1;
    }

    /// @notice Initialize counter
    function reset() external {
        _count = 0;
    }
}