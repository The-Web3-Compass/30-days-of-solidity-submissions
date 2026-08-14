// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;

    event TreasureWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount -= amount;
            emit TreasureWithdrawn(msg.sender, amount);
            return;
        }

        require(amount <= withdrawalAllowance[msg.sender], "You don't have approval for this amount");
        require(amount <= treasureAmount, "Not enough treasure in the chest");

        withdrawalAllowance[msg.sender] -= amount;
        treasureAmount -= amount;
        emit TreasureWithdrawn(msg.sender, amount);
    }
}
