// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ClickCounter {
    uint256 public counter;
    address public immutable owner;

    // Custom errors
    error ClickCounter__NotOwner();
    error ClickCounter__Underflow();

    // Events for off-chain tracking
    event Clicked(uint256 newCount);
    event Decremented(uint256 newCount);
    event Reset(uint256 oldCount);

    constructor() {
        owner = msg.sender;  // Sets owner on deployment 
    }

    /// @notice Increments counter by 1
    /// @dev Uses unchecked for gas savings
    function click() external {
        unchecked {
            counter += 1;
        }
        emit Clicked(counter);
    }

    /// @notice Decrements counter by 1 (reverts on underflow)
    function decrement() external {
        if (counter == 0) revert ClickCounter__Underflow();
        unchecked {
            counter -= 1;
        }
        emit Decremented(counter);
    }

    /// @notice Resets counter to 0 (owner-only)
    function reset() external {
        if (msg.sender != owner) revert ClickCounter__NotOwner();
        emit Reset(counter);
        counter = 0;
    }
}