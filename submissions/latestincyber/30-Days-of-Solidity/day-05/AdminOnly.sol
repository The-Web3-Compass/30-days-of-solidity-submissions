// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied. You are not the owner.");
        _;
    }

    uint256 public treasureAmount;

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    mapping(address => uint256) public withdrawalAllowance;

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure to approve.");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            // Owner can withdraw any amount
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount -= amount;
            return;
        }

        // Regular users can only withdraw up to their approved allowance
        require(amount <= withdrawalAllowance[msg.sender], "Withdrawal amount exceeds your approved allowance.");
        require(amount <= treasureAmount, "Not enough treasury available for this action.");

        withdrawalAllowance[msg.sender] -= amount;
        treasureAmount -= amount;
    }
}

// note to self, when adding transferOwnership, need to prevent owner from being set to address(0) - use this: 
//      require(newOwner != address(0), "New owner cannot be zero address.");