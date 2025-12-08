// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function addTreasure(uint256 _amount) public onlyOwner {
        treasureAmount += _amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
      if(msg.sender == owner){
        require(amount <= treasureAmount, "Not enough treasure");
        treasureAmount -= amount;
        return;
      }

      uint256 allowance = withdrawalAllowance[msg.sender];

      require(allowance > 0, "No allowance set");
      require(amount <= allowance, "Amount exceeds allowance");
      require(!hasWithdrawn[msg.sender], "Already withdrawn");
      require(allowance <= treasureAmount, "Not enough treasure");

      hasWithdrawn[msg.sender] = true;
      treasureAmount -= allowance;
      withdrawalAllowance[msg.sender] = 0;
    }

    function resetWithdrawals(address user) public onlyOwner{
      hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function getTreasureAmount() public view returns (uint256) {
        return treasureAmount;
    }

}