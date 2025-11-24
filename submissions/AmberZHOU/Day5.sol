//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AdminOnly{

    address public owner;
    uint256 public treasureAmount;
    mapping (address => uint256) public withdrawAllowance;
    mapping (address => bool) hasWithdrawn;

    constructor(){

        owner = msg.sender;
    }

    modifier onlyOwner(){
        require (msg.sender == owner, "You don't own this contract");
        _;

    }

    function addTreasure(uint256 amount) public onlyOwner{

        //require(msg.sender == owner, "Access denied: only the owner can perform this action");

        //if this condition passes continue to function logic,
        treasureAmount += amount;

    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner{
        require(amount<= treasureAmount, "Cannot withdraw more than you have");
        withdrawAllowance[recipient] = amount;
    
    }

    function withdrawTreasure(uint256 amount) public {
       if(msg.sender == owner){
            require(amount <= treasureAmount, "Cannot withdraw more than you have");
            treasureAmount-= amount;
            return;
       }

       uint256 allowance = withdrawAllowance[msg.sender];

       require(allowance > 0, "You don't have an allowance");
       require(hasWithdrawn[msg.sender], "You can only withdraw once per day");
       require(allowance <= treasureAmount, "Insufficient allowance");
       require(amount <= allowance, "Cannot withdraw more than allowed");

       hasWithdrawn[msg.sender] = true;
       treasureAmount -= amount;
       withdrawAllowance[msg.sender] =0;

    }

    function resetWithdrawalStatus(address user) public onlyOwner{
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0), "Cannot assign the zero address");
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns(uint256){
        return treasureAmount;
        
    }
}