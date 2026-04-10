// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SendSomeTokens {

    mapping(address => uint) public balances;
    uint public totalSupply;

    constructor() {
        totalSupply = 1000;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint amount) public  {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}