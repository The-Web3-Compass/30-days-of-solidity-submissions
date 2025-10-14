// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    //global variables
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;//a mapping of one's allowanced balance
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;//initialize msg.snder as owner
    }

    //reusable access control with modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }   

    //only owner can add treasure into chest
    function addTreasure(uint256 amount) public onlyOwner{
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner{
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawalAllowanceTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount -= amount;
            return;
        }
        
        //if the withdrawer is not owner, need some prerequisites.
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");

        //finish withdraw
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
    }

    //Resetting a User’s Withdrawal Status
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    //Transferring Ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    //Viewing the Treasure (Owner Only)
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}
