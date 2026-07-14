// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract AdminOnly {
    address public owner;
    uint256 public treasure;

    mapping(address => uint256) public allowedWithdrawal;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner!");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasure += amount;
    }

    function approveWithdrawal(address user, uint256 amount) public onlyOwner {
        require(amount <= treasure, "Not enough treasure to withdraw!");
        allowedWithdrawal[user] = amount;
    }

    function withdraw(uint256 amount) public {
        if (msg.sender == owner) {
            require(amount <= treasure, "Not enough treasure to withdraw!");
            treasure -= amount;
            return;
        }

        uint256 allowedAmount = allowedWithdrawal[msg.sender];
        require(allowedAmount > 0, "You don't have anything to withdraw!");
        require(!hasWithdrawn[msg.sender], "You've already withdrawn!");
        require(allowedAmount <= treasure, "Not enough treasure to withdraw!");

        hasWithdrawn[msg.sender] = true;
        treasure -= allowedAmount;
        allowedWithdrawal[msg.sender] = 0;
    }

    function resetWithdrawal(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "This is not a valid address!");
        owner = newOwner;
    }

    function getDetails() public view returns (uint256) {
        return treasure;
    }
}
