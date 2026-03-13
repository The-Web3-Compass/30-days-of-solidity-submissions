// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

 contract AdminOnly {
    
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) withdrawAllowance;
    mapping (address => bool) hasWithdrawn;
    uint256 allowance;


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "you aren't the owner!");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount; 
    }

    function approveWithdrawal(address recipient, uint amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if(msg.sender == owner )
            require(treasureAmount >= amount, "Not enough funds");
            treasureAmount -= amount;
            return; 

        uint256 allowance = withdrawAllowance[msg.sender];
        require(allowance > = 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in chest");

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawAllowance[msg.sender] = 0;
    }

    function resetWithdrawalStatus(address newOwner) public onlyOwner {
        require(newOwner != address0, "Invalid address");
        newOwner = owner;
    }

    function getTreasureDetails() public view onlyOwner returns {
        return treasureAmount;
         }
     }