// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AdminOnly {
    address public owner;
    uint public treasure;

    mapping(address => bool) public approved;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    // Modifier: Restricts function access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Add treasure (only owner)
    function addTreasure(uint _amount) external onlyOwner {
        treasure += _amount;
    }

    // Approve a user for withdrawal
    function approve(address _user) external onlyOwner {
        approved[_user] = true;
        hasWithdrawn[_user] = false;
    }

    // Withdraw treasure (if approved and not already withdrawn)
    function withdraw(uint _amount) external {
        require(approved[msg.sender], "Not approved");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(_amount <= treasure, "Not enough treasure");

        hasWithdrawn[msg.sender] = true;
        treasure -= _amount;
    }

    // Reset withdrawal statuses for all users (simulated for simplicity)
    function resetUser(address _user) external onlyOwner {
        hasWithdrawn[_user] = false;
    }

    // Transfer ownership to another address
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}
