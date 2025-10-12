// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyFirstToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    address public owner;
    bool public paused;
    mapping(address => bool) public blacklisted;
    
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Pause();
    event Unpause();
    event Blacklist(address indexed account);
    event Unblacklist(address indexed account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "MyFirstToken: caller is not the owner");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "MyFirstToken: token transfers are paused");
        _;
    }
    
    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "MyFirstToken: account is blacklisted");
        _;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
        
        _totalSupply = _initialSupply * 10**_decimals;
        _balances[msg.sender] = _totalSupply;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) 
        public 
        override 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        notBlacklisted(to) 
        returns (bool) 
    {
        require(to != address(0), "MyFirstToken: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "MyFirstToken: insufficient balance");
        
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 amount) 
        public 
        override 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        notBlacklisted(spender) 
        returns (bool) 
    {
        require(spender != address(0), "MyFirstToken: approve to the zero address");
        
        _allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) 
        public 
        override 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        notBlacklisted(from) 
        notBlacklisted(to) 
        returns (bool) 
    {
        require(from != address(0), "MyFirstToken: transfer from the zero address");
        require(to != address(0), "MyFirstToken: transfer to the zero address");
        require(_balances[from] >= amount, "MyFirstToken: insufficient balance");
        require(_allowances[from][msg.sender] >= amount, "MyFirstToken: insufficient allowance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    function mint(address to, uint256 amount) public onlyOwner notBlacklisted(to) {
        require(to != address(0), "MyFirstToken: mint to the zero address");
        require(amount > 0, "MyFirstToken: amount must be greater than 0");
        
        _totalSupply += amount;
        _balances[to] += amount;
        
        emit Transfer(address(0), to, amount);
        emit Mint(to, amount);
    }
    
    function burn(uint256 amount) public whenNotPaused notBlacklisted(msg.sender) {
        require(_balances[msg.sender] >= amount, "MyFirstToken: burn amount exceeds balance");
        require(amount > 0, "MyFirstToken: amount must be greater than 0");
        
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);
    }
    
    function burnFrom(address account, uint256 amount) public whenNotPaused {
        require(_balances[account] >= amount, "MyFirstToken: burn amount exceeds balance");
        require(_allowances[account][msg.sender] >= amount, "MyFirstToken: insufficient allowance");
        
        _balances[account] -= amount;
        _totalSupply -= amount;
        _allowances[account][msg.sender] -= amount;
        
        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) 
        public 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        notBlacklisted(spender) 
        returns (bool) 
    {
        require(spender != address(0), "MyFirstToken: approve to the zero address");
        
        _allowances[msg.sender][spender] += addedValue;
        
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) 
        public 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        notBlacklisted(spender) 
        returns (bool) 
    {
        require(spender != address(0), "MyFirstToken: approve to the zero address");
        require(_allowances[msg.sender][spender] >= subtractedValue, "MyFirstToken: decreased allowance below zero");
        
        _allowances[msg.sender][spender] -= subtractedValue;
        
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
    function pause() public onlyOwner {
        require(!paused, "MyFirstToken: already paused");
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner {
        require(paused, "MyFirstToken: not paused");
        paused = false;
        emit Unpause();
    }
    
    function addToBlacklist(address account) public onlyOwner {
        require(account != address(0), "MyFirstToken: cannot blacklist zero address");
        require(!blacklisted[account], "MyFirstToken: account already blacklisted");
        
        blacklisted[account] = true;
        emit Blacklist(account);
    }
    
    function removeFromBlacklist(address account) public onlyOwner {
        require(blacklisted[account], "MyFirstToken: account not blacklisted");
        
        blacklisted[account] = false;
        emit Unblacklist(account);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "MyFirstToken: new owner is the zero address");
        require(newOwner != owner, "MyFirstToken: new owner is the same as current owner");
        
        address oldOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function getTokenInfo() public view returns (
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 tokenTotalSupply,
        address tokenOwner,
        bool isPaused
    ) {
        return (name, symbol, decimals, _totalSupply, owner, paused);
    }
    
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) 
        public 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        returns (bool) 
    {
        require(recipients.length == amounts.length, "MyFirstToken: arrays length mismatch");
        require(recipients.length > 0, "MyFirstToken: no recipients provided");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(_balances[msg.sender] >= totalAmount, "MyFirstToken: insufficient balance for batch transfer");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "MyFirstToken: transfer to the zero address");
            require(!blacklisted[recipients[i]], "MyFirstToken: recipient is blacklisted");
            
            _balances[msg.sender] -= amounts[i];
            _balances[recipients[i]] += amounts[i];
            
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
        
        return true;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        require(tokenAddress != address(this), "MyFirstToken: cannot recover own tokens");
        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }
}
