// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AdminOnly{

    address public owner;
    uint256 public treasureAmount;
    mapping (address =>uint256) public withdrawalAllowance;
    mapping (address => bool) hasWithdrawn;

    constructor (){

        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"Access denied: Only the owner can perform this action");
        _;
    }

    function addTreasure(uint256 amount) public  onlyOwner{

        //require(msg.sender == owner,"Access denied: Only the owner can perform this action");

        //if this condition passes continue to function logic,
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint256 amount )public onlyOwner{
        require(amount <= treasureAmount,"Insuffcient funds in the contract");
        withdrawalAllowance[recipient] = amount;

    }

    function withdrawTreasure(uint256 amount)public {
        if(msg.sender == owner){
            require(amount <= treasureAmount,"Instufficient funds in the contract");
            treasureAmount -=amount;
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];

        require(allowance > 0,"you do not have any treasure allowance");
        require(!hasWithdrawn[msg.sender],"YOu have already withdrawan your treasure");
        require(allowance <= treasureAmount,"Not enough treasure in the chest"  );
        require(amount <= allowance,"Not enough allowance for witharawl");

        hasWithdrawn[msg.sender] = true;
        treasureAmount -=allowance;
        withdrawalAllowance[msg.sender] = 0;
    }

    function restWithdrawalStatus(address newOwner)public onlyOwner{
        require(newOwner != address(0),"Invalid new wner");
        owner = newOwner;

    }

    function getTreasureDetails() public view onlyOwner returns (uint256){
        return treasureAmount;
    }

}