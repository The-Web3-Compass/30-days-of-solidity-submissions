//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

contract AdminOnly{
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawlAllowance;
    mapping(address => bool) hasWithdrawn;

    constructor(){

        owner = msg.sender;
    }

    modifier onlyOwner(){
        require (msg.sender == owner, "Access denied:  Only the owner perform this action");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner{
        require(amount <= treasureAmount, "Insufficient funds in the contract"); 
        withdrawlAllowance[recipient] = amount;

    }

    function withdralTreasure(uint256 amount) public{
        if(msg.sender == owner){
            require(amount <= treasureAmount, "Insufficient funds in the contract");
            treasureAmount-= amount; 
            return;
        }

        uint256 allowance = withdrawlAllowance[msg.sender];

        require(allowance > 0, "You do not have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasury");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(amount <= allowance, "Not enough allowance for withdrawal");

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawlAllowance[msg.sender] = 0;
    }

    function resetWithdrawalStatus(address user) public onlyOwner{
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner)public onlyOwner{
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

    function getTreasure() public view onlyOwner returns(uint256){
        return treasureAmount;
    }
}