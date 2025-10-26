// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {

    address public owner;
    uint256 public  treasureAmount;
    mapping(address => uint256) public withdrawAllowance;
    mapping(address => bool) public hasWithdraw;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }

    function addTeasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {

        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasure available for this action.");
            treasureAmount -= amount;

            return;
        }
        uint256 allowance = withdrawAllowance[msg.sender];

        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdraw[msg.sender], "You have already withdrawn your treasure.");
        require(allowance <= treasureAmount, "Not enough treasure in the chest.");
        require(allowance >= amount, "Cannot withdraw more than you are allowed");

        hasWithdraw[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawAllowance[msg.sender] = 0;

    }

    function restWithdrawlStatus(address user) public onlyOwner {
        hasWithdraw[user] = false;
    }

    function treasureOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}