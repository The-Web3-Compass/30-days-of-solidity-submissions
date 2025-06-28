// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AMM is ERC20, ReentrancyGuard {
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public constant FEE = 30; // 0.3% fee (30/10000 = 0.003)
    uint256 public constant FEE_BASE = 10000;
    
    event Swap(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn
    );
    
    event LiquidityAdded(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    
    event LiquidityRemoved(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );

    constructor(address _token0, address _token1) 
        ERC20("AMM-LP", "AMM-LP") 
    {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    // Add liquidity to the pool
    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external nonReentrant {
        // Transfer tokens from sender
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);
        
        // Get current balances
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        
        // Calculate amounts to actually add (with ratio preservation)
        uint256 amount0;
        uint256 amount1;
        uint256 _totalSupply = totalSupply();
        
        if (_totalSupply == 0) {
            amount0 = amount0Desired;
            amount1 = amount1Desired;
        } else {
            uint256 amount1Optimal = (amount0Desired * reserve1) / reserve0;
            if (amount1Optimal <= amount1Desired) {
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
                // Refund excess token1
                if (amount1 < amount1Desired) {
                    token1.transfer(msg.sender, amount1Desired - amount1);
                }
            } else {
                uint256 amount0Optimal = (amount1Desired * reserve0) / reserve1;
                require(amount0Optimal <= amount0Desired, "INVALID_AMOUNT");
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
                // Refund excess token0
                if (amount0 < amount0Desired) {
                    token0.transfer(msg.sender, amount0Desired - amount0);
                }
            }
        }

        // Calculate liquidity to mint
        uint256 liquidity;
        if (_totalSupply == 0) {
            liquidity = sqrt(amount0 * amount1);
        } else {
            liquidity = min(
                (amount0 * _totalSupply) / reserve0,
                (amount1 * _totalSupply) / reserve1
            );
        }
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY");
        
        // Mint LP tokens
        _mint(msg.sender, liquidity);
        
        // Update reserves
        reserve0 = balance0;
        reserve1 = balance1;
        
        emit LiquidityAdded(msg.sender, amount0, amount1, liquidity);
    }

    // Remove liquidity from the pool
    function removeLiquidity(
        uint256 liquidity
    ) external nonReentrant {
        // Calculate token amounts proportional to pool share
        uint256 _totalSupply = totalSupply();
        uint256 amount0 = (liquidity * reserve0) / _totalSupply;
        uint256 amount1 = (liquidity * reserve1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY");
        
        // Burn LP tokens
        _burn(msg.sender, liquidity);
        
        // Transfer tokens to sender
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        
        // Update reserves
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
        
        emit LiquidityRemoved(msg.sender, amount0, amount1, liquidity);
    }

    // Swap tokens using constant product formula
    function swap(
        address tokenIn,
        uint256 amountIn
    ) external nonReentrant {
        require(tokenIn == address(token0) || tokenIn == address(token1), "INVALID_TOKEN");
        
        // Transfer input tokens
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        
        // Calculate output amount with fee
        uint256 amountInWithFee = amountIn * (FEE_BASE - FEE) / FEE_BASE;
        uint256 amountOut;
        
        if (tokenIn == address(token0)) {
            amountOut = reserve1 - (reserve0 * reserve1) / (reserve0 + amountInWithFee);
            require(amountOut < reserve1, "INSUFFICIENT_LIQUIDITY");
            token1.transfer(msg.sender, amountOut);
        } else {
            amountOut = reserve0 - (reserve0 * reserve1) / (reserve1 + amountInWithFee);
            require(amountOut < reserve0, "INSUFFICIENT_LIQUIDITY");
            token0.transfer(msg.sender, amountOut);
        }
        
        // Update reserves
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
        
        emit Swap(msg.sender, amountIn, amountOut, tokenIn);
    }

    // Helper function to calculate output for given input
    function getAmountOut(
        address tokenIn,
        uint256 amountIn
    ) external view returns (uint256) {
        require(tokenIn == address(token0) || tokenIn == address(token1), "INVALID_TOKEN");
        
        uint256 amountInWithFee = amountIn * (FEE_BASE - FEE) / FEE_BASE;
        
        if (tokenIn == address(token0)) {
            return reserve1 - (reserve0 * reserve1) / (reserve0 + amountInWithFee);
        } else {
            return reserve0 - (reserve0 * reserve1) / (reserve1 + amountInWithFee);
        }
    }

    // Math utilities
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
    
    function min(uint256 x, uint256 y) private pure returns (uint256) {
        return x < y ? x : y;
    }
}