//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {

    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    // Reusable permission checks that you can attach to functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: only the owner can perform this action");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    function approveWithdrawal(address user, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[user] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        address user = msg.sender;
        if (user == owner) {
            require(amount <= treasureAmount, "Not enough treasure available");
        } else {
            amount = withdrawalAllowance[user];
            require(amount > 0, "You don't have any treasure allowance");
            require(!hasWithdrawn[user], "You have already withdrawn your treasure");
            require(amount <= treasureAmount, "Not enough treasure available");

            hasWithdrawn[user] = true;
            withdrawalAllowance[user] = 0;
        }
        treasureAmount -= amount;
    }

    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(address(0) != newOwner, "Invalid address");
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns(uint256) {
        return treasureAmount;
    }
}