// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MyFirstToken {
    error MyFirstToken_InsufficientBalance();
     error MyFirstToken_InsufficientAllowance();
    error MyFirstToken_UnAuthorized();
    error MyFirstToken_InvalidAddress();

    string private s_name;
    string private s_symbol;
    uint8 private constant DECIMALS = 18;

    uint256 private constant INITIAL_TOKEN_SUPPLY = 1000 * 10**DECIMALS;
    uint256 public constant MAX_SUPPLY = 10_000 * 10**DECIMALS;
    uint256 public tokenSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping(address => uint256)) public allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol) {
        s_name = _name;
        s_symbol = _symbol;
        tokenSupply = INITIAL_TOKEN_SUPPLY;
    }
    

    function name() public view returns (string memory) {
        return s_name;
    }
    
    function symbol() public view returns (string memory) {
        return s_symbol;
    }
    
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public virtual returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success) {
        uint256 currentAllowance = allowances[_from][msg.sender];
        
        if (currentAllowance < _value) revert MyFirstToken_InsufficientAllowance();
        allowances[_from][msg.sender] = currentAllowance - _value;

        if (allowances[_from][msg.sender] < _value) revert MyFirstToken_UnAuthorized();
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_spender == address(0)) revert MyFirstToken_InvalidAddress();
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0) || to == address(0)) {
            revert MyFirstToken_InvalidAddress();
        }
        if (balances[from] < value) {
            revert MyFirstToken_InsufficientBalance();
        }
        // Update balances
        balances[from] -= value;
        balances[to] += value;
        
        emit Transfer(from, to, value);
    }

    // Additional
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        if (spender == address(0)) {
            revert MyFirstToken_InvalidAddress();
        }
        
        allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        if (spender == address(0)) {
            revert MyFirstToken_InvalidAddress();
        }
        
        uint256 currentAllowance = allowances[msg.sender][spender];
        if (currentAllowance < subtractedValue) {
            revert MyFirstToken_InsufficientAllowance();
        }
        
        allowances[msg.sender][spender] = currentAllowance - subtractedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }


}