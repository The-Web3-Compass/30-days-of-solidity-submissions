// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    address public tokenA;
    address public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalShares;
    
    mapping(address => uint256) public shares;
    
    event LiquidityAdded(address user, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address user, uint256 amountA, uint256 amountB, uint256 shares);
    event Swapped(address user, address fromToken, uint256 fromAmount, address toToken, uint256 toAmount);

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // Add liquidity to the pool
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be positive");
        
        // Transfer tokens from user to contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        
        uint256 sharesToMint;
        
        if (totalShares == 0) {
            // First liquidity provider - use geometric mean
            sharesToMint = sqrt(amountA * amountB);
        } else {
            // Calculate shares based on existing reserves
            uint256 shareA = (amountA * totalShares) / reserveA;
            uint256 shareB = (amountB * totalShares) / reserveB;
            sharesToMint = shareA < shareB ? shareA : shareB;
        }
        
        require(sharesToMint > 0, "No shares minted");
        
        // Update user's shares and total supply
        shares[msg.sender] += sharesToMint;
        totalShares += sharesToMint;
        
        // Update reserves
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, sharesToMint);
    }

    // Remove liquidity from the pool
    function removeLiquidity(uint256 sharesToBurn) external {
        require(sharesToBurn > 0 && sharesToBurn <= shares[msg.sender], "Invalid shares");
        
        // Calculate proportional amounts to return
        uint256 amountA = (sharesToBurn * reserveA) / totalShares;
        uint256 amountB = (sharesToBurn * reserveB) / totalShares;
        
        // Update shares
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;
        
        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;
        
        // Return tokens to user
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, sharesToBurn);
    }

    // Calculate output amount for a swap
    function getAmountOut(uint256 inputAmount, address inputToken) public view returns (uint256) {
        require(inputToken == tokenA || inputToken == tokenB, "Invalid token");
        
        uint256 inputReserve;
        uint256 outputReserve;
        
        if (inputToken == tokenA) {
            inputReserve = reserveA;
            outputReserve = reserveB;
        } else {
            inputReserve = reserveB;
            outputReserve = reserveA;
        }
        
        // Apply 0.3% fee (like Uniswap)
        uint256 inputAmountMinusFee = inputAmount * 997;
        uint256 numerator = inputAmountMinusFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountMinusFee;
        
        return numerator / denominator;
    }

    // Swap tokens
    function swap(uint256 inputAmount, address inputToken) external {
        require(inputAmount > 0, "Input amount must be positive");
        require(inputToken == tokenA || inputToken == tokenB, "Invalid token");
        
        address outputToken = (inputToken == tokenA) ? tokenB : tokenA;
        uint256 outputAmount = getAmountOut(inputAmount, inputToken);
        
        require(outputAmount > 0, "Insufficient output");
        
        // Transfer input tokens from user
        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        
        // Transfer output tokens to user
        IERC20(outputToken).transfer(msg.sender, outputAmount);
        
        // Update reserves
        if (inputToken == tokenA) {
            reserveA += inputAmount;
            reserveB -= outputAmount;
        } else {
            reserveB += inputAmount;
            reserveA -= outputAmount;
        }
        
        emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);
    }

    // Get pool information
    function getPoolInfo() external view returns (uint256, uint256, uint256) {
        return (reserveA, reserveB, totalShares);
    }

    // Get user's share balance
    function getShareBalance(address user) external view returns (uint256) {
        return shares[user];
    }

    // Square root helper function
    function sqrt(uint256 y) internal pure returns (uint256 z) {
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