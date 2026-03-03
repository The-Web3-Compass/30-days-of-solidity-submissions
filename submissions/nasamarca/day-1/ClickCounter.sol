// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ClickCounter
 * @author Nadiatus Salam
 * @notice A simple counter contract: each call to click() increases the stored counter by one.
 * @dev Solidity fundamentals exercise: uint256 state variable + increment/decrement/reset functions.
 */
contract ClickCounter {
    uint256 public counter;

    error CounterIsZero();

    event Clicked(address indexed caller, uint256 newCounter);
    event Decremented(address indexed caller, uint256 newCounter);
    event Reset(address indexed caller);

    /**
     * @notice Increments the counter by 1.
     * @dev Callable by anyone.
     */
    function click() external {
        unchecked {
            counter++;
        }
        emit Clicked(msg.sender, counter);
    }

    /**
     * @notice Decrements the counter by 1.
     * @dev Reverts if the counter is already 0.
     */
    function decrement() external {
        if (counter == 0) revert CounterIsZero();
        unchecked {
            counter--;
        }
        emit Decremented(msg.sender, counter);
    }

    /**
     * @notice Resets the counter back to 0.
     */
    function reset() external {
        counter = 0;
        emit Reset(msg.sender);
    }
}