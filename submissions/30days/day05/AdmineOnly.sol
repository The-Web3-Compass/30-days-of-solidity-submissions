// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) withdrawalAllowance;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner,"This action should only done by owner.");
        _;
    }
    function addTreasure(uint256 _amount)public onlyOwner{
        treasureAmount += _amount;
    }
    function approveWithdrawal(address recipient, uint256 _amount) public onlyOwner{
        require(_amount <= treasureAmount,"Not enougth treasure available.");
        withdrawalAllowance[recipient] = _amount;
    }
    function withdrawTreasure(uint256 _amount) public{
        if(msg.sender == owner){
            require(_amount <= treasureAmount,"Not Enougth treasure available.");
            treasureAmount -= _amount;
        }
        require(_amount <= withdrawalAllowance[msg.sender],"You don't have approval  for this  amount.");
        require(_amount <= treasureAmount,"Not Enougth treasure available.");
        withdrawalAllowance[msg.sender] -= _amount;
        treasureAmount -= _amount;
    } 

}