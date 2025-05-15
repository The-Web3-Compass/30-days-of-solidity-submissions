// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MyFirstToken
 * @dev Implementation of the basic ERC20 token standard
 */
contract MyFirstToken {
    // Token details
    string public name = "MyFirstToken";
    string public symbol = "MFT";
    uint8 public decimals = 18;
    
    // Track the total token supply
    uint256 private _totalSupply;
    
    // Track balances for each account
    mapping(address => uint256) private _balances;
    
    // Track allowances (for approve/transferFrom functionality)
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Events (following ERC20 standard)
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
     * @dev Constructor that gives the msg.sender all of the initial tokens
     */
    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply);
    }
    
    /**
     * @dev Returns the total supply of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Returns the balance of the specified address
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev Transfer tokens to a specified address
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    
    /**
     * @dev Returns the remaining tokens that spender is allowed to spend on behalf of owner
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev Approve the spender to spend the specified amount of tokens on behalf of the msg.sender
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    
    /**
     * @dev Transfer tokens from one address to another using the allowance mechanism
     */
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    /**
     * @dev Atomically increases the allowance granted to spender by the caller
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    
    /**
     * @dev Atomically decreases the allowance granted to spender by the caller
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    
    /**
     * @dev Internal function to transfer tokens
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev Internal function to mint new tokens
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        
        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);
    }
    
    /**
     * @dev Internal function to approve spending of tokens
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
     * @dev Internal function to reduce the allowance
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}