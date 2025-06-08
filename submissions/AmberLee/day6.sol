//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AdminOnly{

    address public owner;
    uint256 public treasureAmount;
    mapping (address =>uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;

    constructor (){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "not the owner");
        _;
    }

    function addTreasure (uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    function approveWithdrawal (address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance [recipient] = amount;  
    }
    
    function withdrawTreasure (uint256 amount) public {

        if (msg.sender == owner){
            require (amount <= treasureAmount, "Not enough treasures to withdraw");
            treasureAmount-= amount;
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];    


        require (allowance >0, "You don't have enough treasure");
        require (!hasWithdrawn[msg.sender], "you already withdraw");
        require (allowance <= treasureAmount,"Not enough treasure");
        require (allowance >= amount, "withdrawal is too high");

        hasWithdrawn [msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance [msg.sender] =0;
    }
   
   function resetWithdrawalStatus (address user) public onlyOwner {
        hasWithdrawn [user] = false;
   }

    function transferOwnership (address newOwner) public onlyOwner{
        require (newOwner != address (0),"invalid address");
        owner = newOwner;
    }
 }


