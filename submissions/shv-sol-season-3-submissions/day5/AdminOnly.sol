// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AdminOnly
 * @dev A basic access-controlled contract simulating a treasure chest.
 * Only the owner can add treasure, approve users, and transfer ownership.
 * Approved users can withdraw treasure once, controlled via modifiers and flags.
 * Demonstrates use of `modifier`, `msg.sender`, and mappings for basic access control.
 */


contract AdminOnly {
    address public owner;
    uint256 public treasure;

    mapping(address => bool) public approvedUsers;
    mapping(address => bool) public hasWithdrawn;

    event TreasureAdded(uint256 amount);
    event Withdrawal(address user, uint256 amount);
    event Approval(address user);
    event WithdrawalReset(address user);
    event OwnershipTransferred(address oldOwner, address newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasure += amount;
        emit TreasureAdded(amount);
    }

    function approveUser(address user) public onlyOwner {
        approvedUsers[user] = true;
        hasWithdrawn[user] = false;
        emit Approval(user);
    }

    function withdraw() public {
        require(approvedUsers[msg.sender], "Not approved to withdraw");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(treasure > 0, "No treasure left");

        uint256 amount = treasure / 10; // 10% per user (example)
        treasure -= amount;
        hasWithdrawn[msg.sender] = true;

        emit Withdrawal(msg.sender, amount);
    }

    function resetWithdrawal(address user) public onlyOwner {
        hasWithdrawn[user] = false;
        emit WithdrawalReset(user);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
