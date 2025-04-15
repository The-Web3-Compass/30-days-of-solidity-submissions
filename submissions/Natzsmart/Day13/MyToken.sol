// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// A simple ERC20-like token contract called "Web3 Compass" with symbol "WBT"
contract MyToken {

    // Public token metadata
    string public name = "Web3 Compass";
    string public symbol = "WBT";
    uint8 public decimals = 18; // Standard number of decimals for ERC20 tokens
    uint256 public totalSupply; // Total supply of tokens

    // Mapping to store the balance of each address
    mapping(address => uint256) public balanceOf;

    // Nested mapping to store allowances:
    // owner => (spender => amount allowed to spend)
    mapping(address => mapping(address => uint256)) public allowance;

    // Event emitted on token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Event emitted when an approval is made
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructor: mints initial supply to the deployer's address
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** decimals); // Adjust for decimals
        balanceOf[msg.sender] = totalSupply; // Assign total supply to contract deployer
        emit Transfer(address(0), msg.sender, _initialSupply); // Emit transfer from 0 address (mint)
    }

    // Internal function to handle transfers
    function _transfer(address _from, address _to, uint256 _value) internal virtual {
        require(_to != address(0), "Cannot transfer to the zero address");

        // Decrease sender's balance and increase recipient's balance
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // Emit transfer event
        emit Transfer(_from, _to, _value);
    }

    // Public function to transfer tokens to another address
    function transfer(address _to, uint256 _value) public virtual returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // Function to transfer tokens on behalf of another address
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Not enough allowance");

        // Reduce allowance and perform transfer
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // Approves a spender to spend a certain amount of tokens on the owner's behalf
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;

        // Emit approval event
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}