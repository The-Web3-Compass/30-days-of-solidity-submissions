// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract AdminOnly {
    address public owner;

    mapping (address => uint) public allowance;
    mapping (address => bool) public hasWithdrawn;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor () {
        owner = msg.sender;
    }

    function deposit() public onlyOwner payable {
        require(msg.value > 0, "Deposit amount cannot be empty");
    }

    function getTreasureBalance() public view returns(uint) {
        return address(this).balance;
    }

    function approveWithdrawal(address user, uint amount) public onlyOwner {
        require(user != address(0), "Invalid address");
        require(amount > 0, "Amount cannot be empty");
        allowance[user] += amount;
    }

    function withdraw() external {
        uint amount = allowance[msg.sender];

        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(amount > 0, "No allowance");
        require(address(this).balance >= amount, "Insufficient contract balance");

        hasWithdrawn[msg.sender] = true;
        allowance[msg.sender] = 0;

        (bool s, ) = msg.sender.call{value: amount}("");
        require(s, "Transfer failed");
    }

    function ownerWithdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No funds");

        (bool s, ) = owner.call{value: address(this).balance}("");
        require(s);
    }

    function resetWithdrawal(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");

        owner = newOwner;
    }
}