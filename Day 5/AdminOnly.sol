// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AdminOnly {
    address public owner;
    uint256 public totalTreasure;

    mapping(address => uint256) public allowance;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: owner only");
        _;
    }


    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "invalid address");
        owner = newOwner;
    }

 
    function addTreasure(uint256 amount) external onlyOwner {
        require(amount > 0, "amount should be > 0");
        totalTreasure += amount;
    }

  

    function approveWithdrawal(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "invalid address");
        require(amount > 0, "Montant doit etre > 0");
        allowance[user] = amount;
    }

   
    function withdraw() external {
        require(allowance[msg.sender] > 0, "unauthorized");
        require(!hasWithdrawn[msg.sender], "Deja retire");
        require(totalTreasure >= allowance[msg.sender], "insufficient funds");

        uint256 amount = allowance[msg.sender];
        totalTreasure -= amount;
        hasWithdrawn[msg.sender] = true;

    }

   
    function resetWithdrawals(address user) external onlyOwner {
        hasWithdrawn[user] = false;
    }

  
    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(amount <= totalTreasure, "insufficient funds");
        totalTreasure -= amount;
    }
}
