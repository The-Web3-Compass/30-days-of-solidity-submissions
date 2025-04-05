/*---------------------------------------------------------------------------
  File:   AdminOnly.sol
  Author: Marion Bohr
  Date:   04/05/2025
  Description:
    Build a contract that simulates a treasure chest controlled by an owner. 
    The owner can add treasure, approve withdrawals for specific users, and 
    even withdraw treasure themselves. Other users can attempt to withdraw, 
    but only if the owner has given them an allowance and they haven't 
    withdrawn before. The owner can also reset withdrawal statuses and 
    transfer ownership of the treasure chest. This demonstrates how to create 
    a contract with restricted access using a 'modifier' and `msg.sender`, 
    similar to how only an admin can perform certain actions in a game or 
    application.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract AdminOnly {
    // Variables
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public allowance;
    mapping(address => bool) public hasWithdrawn;

    // Modifier to restrict access to the owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Modifier to ensure the user has permission to withdraw and hasn't withdrawn before
    modifier canWithdraw() {
        require(allowance[msg.sender] > 0, "You are not allowed to withdraw");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn");
        _;
    }

    // Constructor to set the initial owner
    constructor() {
        owner = msg.sender;
    }

    // Function to add treasure to the chest
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    // Function for the owner to approve withdrawals for specific users
    function approveWithdrawal(address user, uint256 amount) public onlyOwner {
        allowance[user] = amount;
    }

    // Function for the owner to withdraw treasure
    function withdrawTreasure(uint256 amount) public onlyOwner {
        require(treasureAmount >= amount, "Not enough treasure in the chest");
        treasureAmount -= amount;
        // Logic for transferring the treasure to the owner (not implemented for simplicity)
    }

    // Function for users to withdraw if approved and if they haven't withdrawn before
    function userWithdraw(uint256 amount) public canWithdraw {
        require(treasureAmount >= amount, "Not enough treasure in the chest");
        require(amount <= allowance[msg.sender], "You are trying to withdraw more than allowed");

        treasureAmount -= amount;
        allowance[msg.sender] -= amount;
        hasWithdrawn[msg.sender] = true;

        // Logic for transferring the treasure to the user (not implemented for simplicity)
    }

    // Function to reset the withdrawal status for a user
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    // Function to transfer ownership of the treasure chest to another address
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}
