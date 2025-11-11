// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/**
 * @title MiniDEX
 * @author Eric (https://github.com/0xxEric)
 * @notice MiniDEX with Simple Governance
 * @dev A simplified decentralized exchange (DEX) inspired by Uniswap.
 *      Includes basic governance controls for fee and pause management.
 */

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MiniDEX is Ownable {
    IERC20 public token;               // ERC20 token traded against ETH
    uint public totalLiquidity;        // Total liquidity in the pool
    mapping(address => uint) public liquidity; // User's liquidity shares

    uint public feeBasisPoints = 30;   // Default fee = 0.3% (30 basis points)
    bool public paused = false;        // Emergency pause flag

    event LiquidityAdded(address indexed provider, uint ethAmount, uint tokenAmount);
    event LiquidityRemoved(address indexed provider, uint ethAmount, uint tokenAmount);
    event TokenSwapped(address indexed trader, string direction, uint inputAmount, uint outputAmount);
    event FeeUpdated(uint newFee);
    event Paused(bool isPaused);

    constructor(address token_addr) {
        token = IERC20(token_addr);
    }

    // --- Governance Functions ---

    /// @notice Update trading fee (only owner)
    /// @param newFee new fee in basis points (e.g., 30 = 0.3%)
    function setFee(uint newFee) external onlyOwner {
        require(newFee <= 100, "Fee too high"); // Max 1%
        feeBasisPoints = newFee;
        emit FeeUpdated(newFee);
    }

    /// @notice Toggle emergency pause (only owner)
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    // --- Core DEX Functions ---

    /// @notice Initialize the liquidity pool (first provider)
    function init(uint tokenAmount) external payable returns (uint) {
        require(totalLiquidity == 0, "Already initialized");
        require(!paused, "DEX is paused");

        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;

        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        emit LiquidityAdded(msg.sender, msg.value, tokenAmount);
        return totalLiquidity;
    }

    /// @notice Add liquidity to the pool
    function deposit() external payable returns (uint) {
        require(!paused, "DEX is paused");

        uint ethReserve = address(this).balance - msg.value;
        uint tokenReserve = token.balanceOf(address(this));
        uint tokenAmount = (msg.value * tokenReserve) / ethReserve;
        uint liquidityMinted = (msg.value * totalLiquidity) / ethReserve;

        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        emit LiquidityAdded(msg.sender, msg.value, tokenAmount);
        return liquidityMinted;
    }

    /// @notice Remove liquidity and redeem ETH + tokens
    function withdraw(uint amount) external returns (uint, uint) {
        require(!paused, "DEX is paused");
        require(amount <= liquidity[msg.sender], "Insufficient liquidity");

        uint ethAmount = (amount * address(this).balance) / totalLiquidity;
        uint tokenAmount = (amount * token.balanceOf(address(this))) / totalLiquidity;

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        payable(msg.sender).transfer(ethAmount);
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit LiquidityRemoved(msg.sender, ethAmount, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    /// @notice Swap ETH for tokens
    function ethToTokenSwap() external payable returns (uint tokenOut) {
        require(!paused, "DEX is paused");
        require(msg.value > 0, "Zero ETH sent");

        uint tokenReserve = token.balanceOf(address(this));
        uint tokenBought = getOutputAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        require(token.transfer(msg.sender, tokenBought), "Token transfer failed");

        emit TokenSwapped(msg.sender, "ETH->Token", msg.value, tokenBought);
        return tokenBought;
    }

    /// @notice Swap tokens for ETH
    function tokenToEthSwap(uint tokenIn) external returns (uint ethOut) {
        require(!paused, "DEX is paused");
        require(tokenIn > 0, "Zero token sent");

        uint tokenReserve = token.balanceOf(address(this));
        uint ethBought = getOutputAmount(tokenIn, tokenReserve, address(this).balance);

        require(token.transferFrom(msg.sender, address(this), tokenIn), "Token transfer failed");
        payable(msg.sender).transfer(ethBought);

        emit TokenSwapped(msg.sender, "Token->ETH", tokenIn, ethBought);
        return ethBought;
    }

    // --- Internal Math Function ---

    /// @notice Constant product formula with fee applied
    function getOutputAmount(uint inputAmount, uint inputReserve, uint outputReserve)
        internal
        view
        returns (uint)
    {
        uint feeAdjusted = 10000 - feeBasisPoints; // e.g. 10000 - 30 = 9970
        uint inputAmountWithFee = inputAmount * feeAdjusted;
        uint numerator = inputAmountWithFee * outputReserve;
        uint denominator = (inputReserve * 10000) + inputAmountWithFee;
        return numerator / denominator;
    }
}
