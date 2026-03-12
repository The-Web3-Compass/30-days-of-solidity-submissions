// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyFirstToken {

    string public name = "MyFirstToken";
    string public symbol = "MFT";
    uint8 public decimals = 18;

    uint public totalSupply;

    // Mapping to store balances
    mapping(address => uint) public balanceOf;

    // Event for transfers
    event Transfer(address indexed from, address indexed to, uint value);

    // Constructor to create initial supply
    constructor(uint _initialSupply) {
        totalSupply = _initialSupply * 10 ** uint(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    // Transfer tokens
    function transfer(address _to, uint _value) public returns (bool) {

        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
}