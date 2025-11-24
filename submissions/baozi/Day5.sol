// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly_MultiWithdraw {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasure");
            treasureAmount -= amount;
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];

        require(allowance > 0, "No allowance");
        require(amount <= allowance, "Exceeds your allowance");
        require(amount <= treasureAmount, "Not enough treasure");

        withdrawalAllowance[msg.sender] -= amount;
        treasureAmount -= amount;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    function getMyAllowance() public view returns (uint256) {
        return withdrawalAllowance[msg.sender];
    }
}
