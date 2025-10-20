// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenInventoryPlugin {
    mapping(address => mapping(address => uint256)) private erc20Balances;
    mapping(address => mapping(address => uint256[])) private erc721Holdings;

    event ERC20Tracked(address indexed user, address indexed token, uint256 amount);
    event ERC721Tracked(address indexed user, address indexed token, uint256 tokenId);

    function trackERC20(address user, address token) external {
        uint256 balance = IERC20(token).balanceOf(user);
        erc20Balances[user][token] = balance;
        emit ERC20Tracked(user, token, balance);
    }

    function getERC20Balance(address user, address token) external view returns (uint256) {
        return erc20Balances[user][token];
    }

}
