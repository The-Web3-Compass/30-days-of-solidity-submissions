// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

contract MyFirstToken {

    // Public variables for token details
    string public name = "AbhiXverse";
    string public symbol = "ABX";
    uint8 public decimals = 18;
    uint256 public totalSupply;


    // Mappings to track balances and allowances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events for logging transfers and approvals
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    // Constructor to initialize the token details and allocate the total supply to the deployer
    constructor(uint256 _initialSupply)  {
        totalSupply = _initialSupply *(10 ** decimals);
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply); 
    }

    // Internal function to handle the transfer of tokens
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != address(0), "Cannot transfer to 0 address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    // Public function to transfer tokens from the sender to a specified address
    function transfer (address _to, uint256 _value) public virtual returns(bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // Public function to transfer tokens from one address to another, using an allowance mechanism
    function transferFrom (address _from, address _to, uint256 _value) public virtual returns (bool) {
        require (balanceOf[_from] >= _value, "Insuficient Balance");
        require (allowance[_from][msg.sender] >= _value, "insufficient allowance");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // Public function to approve a spender to spend a specified amount of tokens on behalf of the sender
    function approve (address _spender, uint256 _value) public returns(bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}