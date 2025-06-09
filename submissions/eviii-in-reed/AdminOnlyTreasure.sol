//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping (address => uint256) public withdrawalAllowance;
    mapping (address => bool) hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    //modifier: a breach which breaks 
    modifier onlyOwner(){
        require(msg.sender == owner, "Access denied: only the owner can perform this action.");
        _; //tell the programme it will pass to addTreasure
    }

    function addTreasure(uint256 amount) public onlyOwner{
        // required condition place here
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Exceeded the largest amount.");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawalTreasure(uint256 amount) public {
        if(msg.sender == owner) {
            require(amount <= treasureAmount, "Exceeded the largest amount.");
            treasureAmount -= amount;
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];

        require(allowance > 0, "You do not have any treasure allowance.");
        require(!hasWithdrawn[msg.sender], "You have already  withdrawn your treasure.");
        require(allowance <= treasureAmount, "You have exceed the largest amount allowed.");
        require(amount <= allowance, "You don't have enough allowance to withdraw.");

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] = 0; //if the person withdrawal is not the owner, she/he can only withdrawal once
    }

    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner.");
        owner = newOwner;
    }

    function getTreasureDetail() view public onlyOwner returns (uint256) {
        return treasureAmount;
    }
}
