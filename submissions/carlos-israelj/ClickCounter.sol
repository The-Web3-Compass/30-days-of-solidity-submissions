// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

/**
 * @title ClickCounter
 * @author Carlos I Jimenez
 * @notice A simple counter contract for educational purposes
 * @dev Implements basic counter functionality with increment, decrement, and reset operations
 */
contract ClickCounter {
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice The current value of the counter
    /// @dev Public state variable, automatically generates a getter function
    uint256 public s_counter;
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emitted when the counter is incremented
    /// @param newValue The new counter value after increment
    event CounterIncremented(uint256 indexed newValue);
    
    /// @notice Emitted when the counter is decremented
    /// @param newValue The new counter value after decrement
    event CounterDecremented(uint256 indexed newValue);
    
    /// @notice Emitted when the counter is reset to zero
    event CounterReset();
    
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Thrown when attempting to decrement below zero
    error ClickCounter__CannotDecrementBelowZero();
    
    /*//////////////////////////////////////////////////////////////
                             FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Increments the counter by 1
     * @dev Increases s_counter by one unit and emits CounterIncremented event
     */
    function click() public {
        s_counter++;
        emit CounterIncremented(s_counter);
    }
    
    /**
     * @notice Decrements the counter by 1
     * @dev Decreases s_counter by one unit if counter > 0
     * @dev Reverts with ClickCounter__CannotDecrementBelowZero if counter is already 0
     */
    function decrease() public {
        if (s_counter == 0) {
            revert ClickCounter__CannotDecrementBelowZero();
        }
        s_counter--;
        emit CounterDecremented(s_counter);
    }
    
    /**
     * @notice Resets the counter to zero
     * @dev Sets s_counter to 0 and emits CounterReset event
     */
    function reset() public {
        s_counter = 0;
        emit CounterReset();
    }
    
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Returns the current counter value
     * @dev View function that doesn't modify state
     * @return The current value of s_counter
     */
    function getCounter() public view returns (uint256) {
        return s_counter;
    }
}