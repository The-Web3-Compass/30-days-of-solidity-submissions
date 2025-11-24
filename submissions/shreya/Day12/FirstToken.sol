// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyOptimizedToken {
    // basic Token Info 
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    //Mappings
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Owner for mint control 
    address public owner;

    // Events 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    //  Constructor 
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        uint256 initialAmount = _initialSupply * (10 ** uint256(decimals));
        totalSupply = initialAmount;
        balanceOf[msg.sender] = initialAmount;
        emit Transfer(address(0), msg.sender, initialAmount);
    }

    // Core ERC20 Functions
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 allowed = allowance[_from][msg.sender];
        require(allowed >= _value, "Allowance too low");

        unchecked {
            allowance[_from][msg.sender] = allowed - _value;
        }

        _transfer(_from, _to, _value);
        return true;
    }

    //  Minting: only owner can mint 
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == owner, "Only owner can mint");
        require(_to != address(0), "Invalid address");

        uint256 mintAmount = _amount * (10 ** uint256(decimals));
        totalSupply += mintAmount;
        balanceOf[_to] += mintAmount;

        emit TokensMinted(_to, mintAmount);
        emit Transfer(address(0), _to, mintAmount);
    }

    //  Burning: any user can burn their tokens 
    function burn(uint256 _amount) external {
        uint256 burnAmount = _amount * (10 ** uint256(decimals));
        require(balanceOf[msg.sender] >= burnAmount, "Not enough balance");

        unchecked {
            balanceOf[msg.sender] -= burnAmount;
            totalSupply -= burnAmount;
        }

        emit TokensBurned(msg.sender, burnAmount);
        emit Transfer(msg.sender, address(0), burnAmount);
    }

    // Internal Transfer
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");

        unchecked {
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
        }

        emit Transfer(_from, _to, _value);
    }
}