// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    
    // ==========================================
    // 1. STATE VARIABLES (Data Storage)
    // ==========================================
    uint256 public counter;
    
    // (Requirement 3) Track Who Clicked
    mapping(address => uint256) public clicksByUser; 


    // ==========================================
    // 2. EVENTS (Notifications)
    // ==========================================
    // (Requirement 4) Add an Event
    event Clicked(address indexed user, uint256 newCount);


    // ==========================================
    // 3. FUNCTIONS (Logic & Actions)
    // ==========================================
    
    // (Requirements 3 & 4 Merged) The upgraded click function
    function click() public {
        counter++;                               // Increase total count
        clicksByUser[msg.sender]++;              // Track this specific user's clicks
        emit Clicked(msg.sender, counter);       // Broadcast the event
    }

    // (Requirement 2) A Decrement Function with safety checks
    function decrement() public {
        // Check 1: Global counter isn't zero
        require(counter > 0, "Counter is already at zero");
        
        // Check 2: This specific user actually has clicks to remove
        require(clicksByUser[msg.sender] > 0, "User has no clicks to decrement");
        
        counter--;                     // Decrease global total
        clicksByUser[msg.sender]--;    // Decrease the user's specific total
    }

    // (Requirement 1) A Reset Function
    function reset() public {
        counter = 0;
    }
}