
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PreorderTokens {
    using SafeERC20 for IERC20;

    address public immutable owner;

    mapping(address => uint256) public tokenPrices;
    mapping(address => bool) public validToken;

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function purchaseByEth(address _token) public payable {
        require(msg.value > 0, "Amount must be greater than zero");
        require(validToken[_token], "Invalid token");

        uint256 amount = msg.value / tokenPrices[_token];
        require(IERC20(_token).balanceOf(address(this)) >= amount, "Insufficient token balance");

        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function purchaseByTokenAmount(address _token, uint256 _tokenAmount) public payable {
        require(msg.value > 0, "ETH amount must be greater than zero");
        require(validToken[_token], "Invalid token");

        uint256 expectedTokenAmount = msg.value / tokenPrices[_token];
        require(expectedTokenAmount <= _tokenAmount, "Not enough ETH to buy specified amount");

        uint256 excessTokens = _tokenAmount - expectedTokenAmount;

        // Refund excess ETH
        if (excessTokens > 0) {
            uint256 refund = excessTokens * tokenPrices[_token];
            (bool sent, ) = msg.sender.call{value: refund}("");
            require(sent, "Refund failed");
        }

        IERC20(_token).safeTransfer(msg.sender, expectedTokenAmount);
    }

    function listToken(address _token, uint256 price) public onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(price > 0, "Price must be greater than zero");

        validToken[_token] = true;
        tokenPrices[_token] = price;
    }
}

