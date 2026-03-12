// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AdminOnly {

    address public owner;
    uint public treasure;

    mapping(address => uint) public allowance;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    // Modifier for owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Owner adds treasure to the contract
    function addTreasure() public payable onlyOwner {
        treasure += msg.value;
    }

    // Owner sets withdrawal allowance for a user
    function approveWithdrawal(address _user, uint _amount) public onlyOwner {
        allowance[_user] = _amount;
    }

    // User withdraws approved treasure
    function withdraw() public {
        require(allowance[msg.sender] > 0, "No allowance given");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");

        uint amount = allowance[msg.sender];

        hasWithdrawn[msg.sender] = true;
        treasure -= amount;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Transfer failed");
    }

    // Owner withdraws treasure
    function ownerWithdraw(uint _amount) public onlyOwner {
        require(_amount <= treasure, "Not enough treasure");

        treasure -= _amount;

        (bool sent, ) = payable(owner).call{value: _amount}("");
        require(sent, "Transfer failed");
    }

    // Reset user withdrawal status
    function resetWithdrawal(address _user) public onlyOwner {
        hasWithdrawn[_user] = false;
    }

    // Transfer ownership
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}