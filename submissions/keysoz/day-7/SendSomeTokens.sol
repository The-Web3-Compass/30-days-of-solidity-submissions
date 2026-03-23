// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error SendSomeToken__UnauthorizedAccount(address nonOwner);
error SendSomeToken__NotAllowedZeroAmount();
error SendSomeToken__InsufficientBalance(uint256 amount, uint256 balance);
error SendSomeToken__InvalidAddress(address user);

contract SendSomeEther {
    address private s_owner;
    string private s_name;
    string private s_symbol;
    uint256 private s_initialSupply;
    uint256 private s_totalSupply;

    mapping(address => uint256) private balance;
    mapping(address => mapping(address => uint256)) private allowance;

    event Transfer(address indexed sender, address indexed receiver, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 indexed amount);
    event Mint(address indexed receiver, uint256 amount);
    event Burn(address indexed user, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert SendSomeToken__UnauthorizedAccount(msg.sender);
        _;
    }

    modifier checkAddress(address _receiver) {
        if (_receiver == address(0)) revert SendSomeToken__InvalidAddress(_receiver);
        _;
    }

    modifier checkAmount(uint256 _amount) {
        if (_amount == 0) revert SendSomeToken__NotAllowedZeroAmount();
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) checkAmount(_initialSupply) {
        s_owner = msg.sender;
        s_name = _name;
        s_symbol = _symbol;
        s_initialSupply = _initialSupply;
    }

    function mint(address receiver, uint256 amount) external onlyOwner checkAddress(receiver) checkAmount(amount) {
        balance[receiver] += amount;
        s_totalSupply += amount;
        emit Mint(receiver, amount);
    }

    function burn(uint256 amount) external checkAmount(amount) {
        address sender = msg.sender;
        balance[sender] -= amount;
        s_totalSupply -= amount;
        emit Burn(sender, amount);
    }

    function transfer(address receiver, uint256 amount)
        external
        checkAddress(receiver)
        checkAmount(amount)
        returns (bool)
    {
        address sender = msg.sender;
        balance[sender] -= amount;
        balance[receiver] += amount;
        emit Transfer(sender, receiver, amount);
        return true;
    }

    function transferFrom(address owner, address spender, uint256 amount)
        external
        checkAddress(spender)
        checkAmount(amount)
        returns (bool)
    {
        if (msg.sender != owner) revert SendSomeToken__UnauthorizedAccount(owner);
        balance[owner] -= amount;
        balance[spender] += amount;
        emit Transfer(owner, spender, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function name() external view returns (string memory) {
        return s_name;
    }

    function symbol() external view returns (string memory) {
        return s_symbol;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function setAllowance(address owner, address spender) external view returns (uint256) {
        return allowance[owner][spender];
    }

    function balanceOf(address user) external view returns (uint256) {
        return balance[user];
    }

    function totalSupply() external view returns (uint256) {
        return s_totalSupply;
    }
}
