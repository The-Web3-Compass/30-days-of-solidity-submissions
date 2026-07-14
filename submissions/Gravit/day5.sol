// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Insufficient treasure");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Insufficient treasure");
            treasureAmount -= amount;
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];

        require(allowance > 0, "No allowance");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(amount <= allowance, "Exceeds allowance");
        require(amount <= treasureAmount, "Insufficient treasure");

        hasWithdrawn[msg.sender] = true;
        withdrawalAllowance[msg.sender] = 0;
        treasureAmount -= amount;
    }

    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}
