// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    mapping(address => bool) public allowed;
    mapping(address => bool) public withdrawn;
    uint public treasure;

    constructor() {
        owner = msg.sender; // set the deployer as the owner
    }

    // Modifier for restricted access
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Deposit treasure (only owner)
    function addTreasure() public payable onlyOwner {
        treasure += msg.value;
    }

    // Approve specific users for withdrawal
    function approve(address user) public onlyOwner {
        allowed[user] = true;
    }

    // Withdraw treasure (only if approved)
    function withdraw(uint amount) public {
        require(allowed[msg.sender], "Not approved");
        require(!withdrawn[msg.sender], "Already withdrawn");
        require(amount <= treasure, "Not enough treasure");

        withdrawn[msg.sender] = true;
        treasure -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Reset withdrawal statuses (only owner)
    function resetWithdrawals(address user) public onlyOwner {
        withdrawn[user] = false;
    }

    // Transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}