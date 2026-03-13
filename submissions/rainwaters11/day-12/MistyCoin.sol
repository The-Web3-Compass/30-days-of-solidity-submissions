// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MistyCoin
 * @dev A manual implementation of the ERC-20 standard for Day 12.
 * This contract demonstrates the core mechanics of balances, allowances, and transfers.
 */
contract MistyCoin {
    string public name = "MistyCoin";
    string public symbol = "WATERS";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        // We multiply the human-readable number (e.g., 1,000,000)
        // by 10^18 to handle the 18 decimal places.
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;

        // Signal the minting of the entire supply to the deployer
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // SECURITY FIX: Prevent the race condition
        require(_value == 0 || allowance[msg.sender][_spender] == 0, "Reset allowance to 0 first");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // Internal engine that moves the actual numbers in the ledger
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
}
