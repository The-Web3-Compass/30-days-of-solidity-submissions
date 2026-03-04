// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    
    // ==========================================
    // 1. STATE VARIABLES 
    // ==========================================
    uint256 public counter;
    address public owner; // Tracks who deployed the contract
    mapping(address => uint256) public clicksByUser; 

    // ==========================================
    // 2. EVENTS
    // ==========================================
    event Clicked(address indexed user, uint256 newCount);
    event Decremented(address indexed user, uint256 newCount); // Added missing event
    event Reset(address indexed user); // Restored missing event

    // ==========================================
    // 3. CONSTRUCTOR (Runs only once on deployment)
    // ==========================================
    constructor() {
        owner = msg.sender; // The person deploying becomes the owner
    }

    // ==========================================
    // 4. FUNCTIONS 
    // ==========================================
    function click() public {
        counter++;                               
        clicksByUser[msg.sender]++;              
        emit Clicked(msg.sender, counter);       
    }

    function decrement() public {
        require(counter > 0, "Counter is already at zero");
        require(clicksByUser[msg.sender] > 0, "User has no clicks to decrement");
        
        counter--;
        clicksByUser[msg.sender]--;
        
        emit Decremented(msg.sender, counter); // Broadcast the decrement
    }

    function reset() public {
        // Access Control: Only the owner can call this!
        require(msg.sender == owner, "Only the owner can reset the counter");
        
        counter = 0;
        emit Reset(msg.sender); // Broadcast the reset
    }
}