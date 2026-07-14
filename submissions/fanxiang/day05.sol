// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract adminOnlyContract {
    adress public owner;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    uint256 public treasureAmount;
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    mapping(address => uint256) public withdrawalAllowance;
    function approveWithdrawal(adress recipient, uint256 amount) public onlyOwner{
        require(amount <= treasureAmount, "Not enough treasure to withdraw");
        withdrawalAllowance[recipient] = amount;
    }
    mapping(address => bool) public hasWithdrawn;
    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasure to withdraw");
            treasureAmount -= amount;
            return;
        } 
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0,"No withdrawal allowance");
        require(!hasWithdrawn[msg.sender],"Already withdrawn");
        require(allowance <= treasureAmount, "Not enough treasure to withdraw");
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] -= 0;
    }
    function resetWithdrawalStatus(address user) public onlyOwner{ 
        hasWithdrawn[user] = false;
    }
    function transferOwnership(adress newOwner) public onlyOwner{ 
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    function getTreasureDetails() public view onlyOwner returns (uint256){
        return treasureAmount;
    }

}