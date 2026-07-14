//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

contract AdminOnly{
    address public owner;
    uint public treasureBalance;
    mapping(address => uint) public allowance;
    mapping(address => bool) public hasWithdrawn;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    function addTreasure(uint amount) public onlyOwner {
        treasureBalance += amount;
    }

    function approveWithdrawal(address user, uint amount) public onlyOwner {
        allowance[user] = amount;
        require(allowance[user] > 0);
    }

    function userWithdraw() public {
        uint amount = allowance[msg.sender];
        require(amount > 0, "No allowance");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(treasureBalance >= amount, "Not enough treasure");
        hasWithdrawn[msg.sender] = true;
        treasureBalance -= amount;
    }

    function ownerWithdraw(uint amount) public onlyOwner {
        require(treasureBalance >= amount, "Not enough treasure");
        treasureBalance -= amount;
    }

    function resetWithdrawal(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid Owner");
        owner = newOwner;
    }
}