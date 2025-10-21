// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.1;
/*
    Let's make your own digital currency! 
    You'll create a basic token that can be transferred between users, 
    implementing the ERC20 standard. It's like creating your own in-game money, 
    demonstrating how to create and manage tokens.
*/

contract MyFirstToken {

    string public name = "MyFirstToken";
    string public symbol = "MFT";
    uint8 public decimals = 18;
    uint256 public totalTokens;

    mapping(address => uint256) public balanceOfTokens;
    mapping(address => mapping(address => uint256)) public tokensAllowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        totalTokens = _initialSupply * (10 ** uint256(decimals));
        balanceOfTokens[msg.sender] = totalTokens;
        emit Transfer(address(0), msg.sender, totalTokens);
    }

    function transfer(address _recipient, uint256 _value) public returns (bool) {
        require(balanceOfTokens[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _recipient, _value);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _value) public returns (bool) {
        require(balanceOfTokens[_sender] >= _value, "Not enough balance");
        require(tokensAllowance[_sender][msg.sender] >= _value, "Allowance too low");

        tokensAllowance[_sender][msg.sender] -= _value;
        _transfer(_sender, _recipient, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        tokensAllowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _value) internal {
        require(_recipient != address(0), "Invalid address, try again!");
        balanceOfTokens[_sender] -= _value;
        balanceOfTokens[_recipient] += _value;
        emit Transfer(_sender, _recipient, _value);
    }
}

