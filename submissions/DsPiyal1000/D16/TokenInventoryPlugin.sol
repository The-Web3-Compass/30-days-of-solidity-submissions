// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TokenInventoryPlugin {
    mapping(address => mapping(address => uint256)) private erc20Balances;

    event ERC20Tracked(address indexed user, address indexed token, uint256 amount);

    function trackERC20(address user, address token) external {
        require(user != address(0) && token != address(0), "Invalid address");
        uint256 balance = IERC20(token).balanceOf(user);
        erc20Balances[user][token] = balance;
        emit ERC20Tracked(user, token, balance);
    }

    function getERC20Balance(address user, address token) external view returns (uint256) {
        return erc20Balances[user][token];
    }
}