// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MiniDex.sol
 * @dev A minimal decentralized exchange (DEX) for swapping two ERC20 tokens
 * Concepts:
 * - Liquidity pools
 * - Constant product formula (x * y = k)
 * - Swapping tokens
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MiniDex is ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidityBalance;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityBurned);
    event Swapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /**
     * @dev Add liquidity to the pool
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant returns (uint256 liquidityMinted) {
        require(amountA > 0 && amountB > 0, "Invalid liquidity amounts");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if (totalLiquidity == 0) {
            liquidityMinted = sqrt(amountA * amountB);
        } else {
            liquidityMinted = min(
                (amountA * totalLiquidity) / reserveA,
                (amountB * totalLiquidity) / reserveB
            );
        }

        reserveA += amountA;
        reserveB += amountB;
        totalLiquidity += liquidityMinted;
        liquidityBalance[msg.sender] += liquidityMinted;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidityMinted);
    }

    /**
     * @dev Remove liquidity and receive tokens back
     */
    function removeLiquidity(uint256 liquidityAmount) external nonReentrant {
        require(liquidityBalance[msg.sender] >= liquidityAmount, "Insufficient liquidity");

        uint256 amountA = (liquidityAmount * reserveA) / totalLiquidity;
        uint256 amountB = (liquidityAmount * reserveB) / totalLiquidity;

        liquidityBalance[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;
        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidityAmount);
    }

    /**
     * @dev Swap tokenA for tokenB or vice versa using x*y=k formula
     */
    function swap(address tokenIn, uint256 amountIn) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid amount");
        bool isAToB = tokenIn == address(tokenA);
        require(isAToB || tokenIn == address(tokenB), "Invalid token");

        if (isAToB) {
            tokenA.transferFrom(msg.sender, address(this), amountIn);
            uint256 amountInWithFee = (amountIn * 997) / 1000; // 0.3% fee
            amountOut = (reserveB * amountInWithFee) / (reserveA + amountInWithFee);
            reserveA += amountIn;
            reserveB -= amountOut;
            tokenB.transfer(msg.sender, amountOut);
            emit Swapped(msg.sender, address(tokenA), amountIn, address(tokenB), amountOut);
        } else {
            tokenB.transferFrom(msg.sender, address(this), amountIn);
            uint256 amountInWithFee = (amountIn * 997) / 1000;
            amountOut = (reserveA * amountInWithFee) / (reserveB + amountInWithFee);
            reserveB += amountIn;
            reserveA -= amountOut;
            tokenA.transfer(msg.sender, amountOut);
            emit Swapped(msg.sender, address(tokenB), amountIn, address(tokenA), amountOut);
        }
    }

    // Utility functions
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
