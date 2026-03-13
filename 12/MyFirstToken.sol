// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFirstToken {

    string public name = "MyFirstToken";
    string public symbol = "MFT";
    uint8 public decimals = 18;

    uint public totalSupply;

    mapping(address => uint) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint value);

    constructor(uint _initialSupply) {
        totalSupply = _initialSupply * 10 ** uint(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint _value) public returns(bool) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
}