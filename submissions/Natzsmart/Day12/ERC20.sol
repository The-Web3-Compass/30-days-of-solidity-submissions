// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A basic implementation of an ERC20-like token
contract SimpleERC20 {
    string public name = "SimpleToken";     // Token name
    string public symbol = "SIM";           // Token symbol
    uint8 public decimals = 18;             // Decimal places (like Ether: 1 ETH = 10^18 wei)
    uint256 public totalSupply;             // Total token supply

    // Maps address to token balance
    mapping(address => uint256) public balanceOf;

    // Maps owner to spender to amount allowed for spending
    mapping(address => mapping(address => uint256)) public allowance;

    // Event triggered when tokens are transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Event triggered when an approval is made
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructor to initialize total supply and assign all tokens to deployer
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** uint256(decimals)); // Adjusting for decimals
        balanceOf[msg.sender] = totalSupply; // Assign total supply to contract deployer
        emit Transfer(address(0), msg.sender, totalSupply); // Emit initial mint event
    }

    // Allows user to transfer tokens to another address
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // Allows user to approve another address to spend tokens on their behalf
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Allows a spender to transfer tokens from another address (after approval)
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // Internal function to handle token transfers
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
}