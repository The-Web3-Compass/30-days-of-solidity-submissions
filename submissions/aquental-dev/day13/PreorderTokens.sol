// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreorderTokens is ReentrancyGuard, Ownable {
    IERC20 public immutable token;
    uint256 public constant TOKENS_PER_ETH = 1000; // 1000 tokens per 1 ETH
    uint256 public constant MAX_TOKENS_TO_SELL = 1_000_000 * 10 ** 18; // 1M tokens
    uint256 public tokensSold;
    bool public saleActive;

    // Track user purchases
    mapping(address => uint256) public userPurchases;

    // Events for transparency
    event TokensPurchased(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    event SaleToggled(bool isActive);
    event TokensWithdrawn(address indexed owner, uint256 amount);
    event EtherWithdrawn(address indexed owner, uint256 amount);

    // Constructor sets the token address and initializes owner
    constructor(address _tokenAddress) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
        saleActive = false; // Sale starts inactive
    }

    // Allows users to buy tokens with ETH at the fixed rate
    function buyTokens() external payable nonReentrant {
        require(saleActive, "Sale is not active");
        require(msg.value > 0, "ETH amount must be greater than 0");

        uint256 tokenAmount = msg.value * TOKENS_PER_ETH;
        require(
            tokensSold + tokenAmount <= MAX_TOKENS_TO_SELL,
            "Exceeds available tokens"
        );
        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Insufficient contract token balance"
        );

        tokensSold += tokenAmount;
        userPurchases[msg.sender] += tokenAmount;

        require(
            token.transfer(msg.sender, tokenAmount),
            "Token transfer failed"
        );
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // Allows owner to toggle sale active/inactive
    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
        emit SaleToggled(saleActive);
    }

    // Allows owner to withdraw unsold tokens
    function withdrawTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            token.balanceOf(address(this)) >= amount,
            "Insufficient token balance"
        );
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit TokensWithdrawn(msg.sender, amount);
    }

    // Allows owner to withdraw collected ETH
    function withdrawEther() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "ETH transfer failed");
        emit EtherWithdrawn(msg.sender, balance);
    }

    // View function to check available tokens
    function tokensAvailable() external view returns (uint256) {
        return MAX_TOKENS_TO_SELL - tokensSold;
    }

    // Fallback function to prevent accidental ETH transfers
    receive() external payable {
        revert("Use buyTokens function to purchase");
    }
}
