// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
  address public owner;
  uint256 public treasureAmount;
  mapping(address => uint256) withdrawalAllowance;
  mapping(address => bool) hasWithdrawn;
  
  constructo
  {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender,"You can't perform this action.");
    _;
  }

  function addAmount(uint256 _amount) public onlyOwner{
    treasureAmount += _amount;
  }

  function approveWithdrawal(address recipient, uint256 _amount) public onlyOwner {
    withdrawalAllowance[recipient] = _amount;
  }

  uint public allowance = withdrawalAllowance[msg.sender];
  function withdrawTreasure(uint256 _amount) public {
    require(_amount <= allowance && allowance <= treasureAmount,"Not enough treasure amount.");
    require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
    treasureAmount -= _amount;
    hasWithdrawn[msg.sender] = true;
  }

  
}
