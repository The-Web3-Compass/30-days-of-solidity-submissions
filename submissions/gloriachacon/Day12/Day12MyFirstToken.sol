// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

error ZeroAddress();
error InsufficientBalance(uint256 requested, uint256 available);

contract MyFirstToken is IERC20 {
    string public name = "MyFirstToken";
    string public symbol = "MFT";
    uint8  public constant decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(uint256 initialSupply) {
        if (initialSupply == 0) revert InsufficientBalance(0, 0);
        _mint(msg.sender, initialSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        uint256 bal = _balances[msg.sender];
        if (amount > bal) revert InsufficientBalance(amount, bal);
        unchecked {
            _balances[msg.sender] = bal - amount;
            _balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}