// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    
    // ==========================================
    // 1. STATE VARIABLES 
    // ==========================================
    uint256 public counter;
    address public owner;
    // Epoch is incremented on every reset so that per-user counts from
    // previous rounds are logically cleared without an unbounded loop.
    uint256 public epoch;
    mapping(uint256 => mapping(address => uint256)) public clicksByUser;

    // ==========================================
    // 2. EVENTS
    // ==========================================
    event Clicked(address indexed user, uint256 newCount);
    event Decremented(address indexed user, uint256 newCount);
    event Reset(address indexed owner, uint256 newEpoch);

    // ==========================================
    // 3. CONSTRUCTOR (Runs only once on deployment)
    // ==========================================
    constructor() {
        owner = msg.sender;
    }

    // ==========================================
    // 4. FUNCTIONS 
    // ==========================================
    function click() public {
        counter++;
        clicksByUser[epoch][msg.sender]++;
        emit Clicked(msg.sender, counter);
    }

    // Any user may undo their own clicks in the current epoch.
    // They cannot affect clicks they did not personally register.
    function decrement() public {
        require(counter > 0, "Counter is already at zero");
        require(
            clicksByUser[epoch][msg.sender] > 0,
            "No clicks to decrement in current epoch"
        );

        counter--;
        clicksByUser[epoch][msg.sender]--;

        emit Decremented(msg.sender, counter);
    }

    // Only the owner can reset. Advancing the epoch means every
    // clicksByUser[newEpoch][user] starts at zero — consistent with
    // counter = 0 — without iterating or deleting any storage slots.
    function reset() public {
        require(msg.sender == owner, "Only the owner can reset the counter");

        counter = 0;
        epoch++;

        emit Reset(msg.sender, epoch);
    }
}