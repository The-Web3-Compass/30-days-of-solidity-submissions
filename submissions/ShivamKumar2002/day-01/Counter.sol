// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Counter
/// @author shivam

contract Counter {
    uint256 private count = 0;

    /// @notice Get current count
    /// @return count
    function getCount() external view returns (uint256) {
        return count;
    }

    /// @notice Increment counter by 1
    /// @dev It ensures that count doesn't overflow
    function increment() public {
        assert(count + 1 > count);
        count++;
    }

    /// @notice Decrement counter by 1
    function decrement() public {
        if (count == 0) {
            return;
        }
        count--;
    }
}
