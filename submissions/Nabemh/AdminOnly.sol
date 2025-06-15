// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AdminOnly {
    address owner;
    string treasure;
    uint256 totalBalance;
    
    mapping(address => uint256) allowance;
    mapping(address => bool) hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function addTreasure(string memory _treasure, uint amount) onlyOwner public {
        require (amount > 0, "Has to be greater thatn 0");
        treasure = _treasure;
        totalBalance += amount;
    }

    function approveWithdrawal(address user, uint256 amount) onlyOwner public {
        allowance[user] = amount;
        hasWithdrawn[user] = false;
    }

    function withdraw() public {
        require (allowance[msg.sender] > 0, "Not enough treasure");
        require (!hasWithdrawn[msg.sender], "User has withdrawn");

        if(totalBalance >= allowance[msg.sender]) {
            totalBalance -= allowance[msg.sender];
            hasWithdrawn[msg.sender] = true;
        }
    }

    function ownerWithdraw(uint256 amount) onlyOwner public {
        require (amount > 0, "Has to be greater than 0");

        if(totalBalance >= amount) {
            totalBalance -= amount;
        }
    }

    function resetWithdrawal(address user) onlyOwner public {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function getbalance() public view onlyOwner returns (uint256) {
        return totalBalance;
    }
}