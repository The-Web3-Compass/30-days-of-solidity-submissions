//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;
    uint256 public treasureAmount;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint256) public withdrawalAllowance;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only the owner can perform this action.");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available!");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint amount) public {
        if(msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasure available!");
            treasureAmount -= amount;
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];

        require(allowance >0, "You don't have any treasure!");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(amount <= allowance, "You don't have enough treasure!");

        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] -= amount;

        hasWithdrawn[msg.sender] = true;
    }

    function resetWithdrawalStatus(address user) public onlyOwner{
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0));
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns(uint256){
        return(treasureAmount);
    }

}
