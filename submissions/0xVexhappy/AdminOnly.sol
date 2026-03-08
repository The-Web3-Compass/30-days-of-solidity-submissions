// SPDX-License-Identifier: MIT
// @author 0xVexhappy

pragma solidity ^0.8.31;

contract AdminOnly{
    address public  owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Access denied: Only the owner can perform this action!");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner{
        require(amount <= treasureAmount, "Not enough treasure available!");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            // Owner can withdraw anything
            require(amount <= treasureAmount, "Not enough treasure available for this action!");
            treasureAmount -= amount;
            return;
        }

        require(amount <= withdrawalAllowance[msg.sender], "You dont have approval for this amount!");
        require(amount <= treasureAmount, "Not enough treasure available!");

        withdrawalAllowance[msg.sender] -= amount;
        treasureAmount -= amount;

    }
}
