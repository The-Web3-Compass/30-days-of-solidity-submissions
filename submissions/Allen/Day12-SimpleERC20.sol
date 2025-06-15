// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract SimpleERC20{
    /**
    ERC stands for Ethereum Request for Comments
    */
    string public name = "MyToken";
    string public symbol = "MT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    // Tracking who’s allowed to spend tokens on behalf of whom — and how much.
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(uint256 _initialSupply){
        // ERC-20 tokens use decimals for precision (just like ETH uses wei).
        // totalSupply = _initialSupply * 10 ** 18;
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to,uint256 _value) public returns(bool) {
        require(_to != address(0),"Invalid address");
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);

        return true;
    }

    /**
    This is the foundation of all delegated token movements —
    like trading on a DEX, subscribing to a service, or participating in yield farming.
    */
    function approval(address _spender,uint256 _value) public returns(bool){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns(bool){
        require(_to != address(0),"Invalid target address");
        require(_from != address(0),"Invalid sender's address");
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;

    }




}