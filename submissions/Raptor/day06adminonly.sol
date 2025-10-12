// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool)public hasWithdrawn;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function getTreasureLeft() public view onlyOwner returns(uint256){
        return treasureAmount;
    }
    
    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient,uint256 receiveAmount) public onlyOwner{
        require( receiveAmount <= treasureAmount,"ur giving too much lol");
        withdrawalAllowance[recipient] = receiveAmount;
    }

    function resetWithdrawalStatus(address recipient)public onlyOwner{
        hasWithdrawn[recipient] = false;
    }

    function transferOwnership(address newOwner)public onlyOwner{
        require(newOwner != address(0),"Invalid address");
        owner = newOwner;
    }

    function receiveTreasure(uint256 receiveAmount)public{
        if (msg.sender == owner){
            require(receiveAmount <= treasureAmount,"ur taking too much lol");
            treasureAmount-=receiveAmount;
            return;
        }


        uint256 allowance = withdrawalAllowance[msg.sender];
        
        require (!hasWithdrawn[msg.sender],"You have already withdrawn yet!");
        require (allowance >0,"You are not allowed to take more treasure!");
        require (receiveAmount <= allowance,"Ur taking toooo much!");
        require (receiveAmount <= treasureAmount,"Not enough treasure in the chest!");
        

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] -= receiveAmount;

    }







}