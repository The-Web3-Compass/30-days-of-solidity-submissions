// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AdminOnly {
    address public owner;
    uint public treasure;

    mapping(address => uint256) public allowance;
    mapping(address => bool) public withdrawn;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addTreasure(uint256 amount) external onlyOwner {
        treasure += amount;
    }

    function approveWithdrawal(address user, uint256 amount) external onlyOwner {
        require(amount <= treasure, "Not enough treasure available");
        allowance[user] = amount;
        withdrawn[user] = false; 
    }

    function resetWithdrawalStatus(address user) external onlyOwner {
        withdrawn[user] = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function withdraw() external {
        require(!withdrawn[msg.sender], "You have already withdrawn");
        uint256 amount = allowance[msg.sender];
        require(amount > 0, "You are not approved for withdrawal");
        require(treasure >= amount, "Not enough treasure in the chest");

        withdrawn[msg.sender] = true;
        treasure -= amount;
    }

    function getTreasure() external view onlyOwner returns (uint256) {
        return treasure;
    }
}