// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; 

contract SimpleERC20 {
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint256 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    error InsufficientBalance();
    error InsufficientAllowance();
    error TransferToZeroAddress();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public virtual returns (bool) {
        if (balanceOf[msg.sender] < _value) revert InsufficientBalance();
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal virtual {
        if (_to == address(0)) revert TransferToZeroAddress();
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool) {
        if (allowance[_from][msg.sender] < _value) revert InsufficientAllowance();
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);  // Reuses balance check
        return true;
    }

    function approve(address _spender, uint256 value) public returns (bool) {
        allowance[msg.sender][_spender] = value;
        emit Approval(msg.sender, _spender, value);
        return true;
    }
}