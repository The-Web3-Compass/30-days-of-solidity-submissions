// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AutomatedMarketMaker {
    address public tokenA;
    address public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;
    
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityTokens);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityTokens);
    event TokenSwapped(address indexed user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be positive");
        
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        
        if (totalLiquidity == 0) {
            reserveA = amountA;
            reserveB = amountB;
            totalLiquidity = sqrt(amountA * amountB);
            liquidity[msg.sender] = totalLiquidity;
        } else {
            uint256 amountBOptimal = (amountA * reserveB) / reserveA;
            require(
                amountB >= amountBOptimal && 
                amountB <= (amountBOptimal * 101) / 100,
                "Invalid token ratio"
            );
            
            if (amountB > amountBOptimal) {
                uint256 excessB = amountB - amountBOptimal;
                IERC20(tokenB).transfer(msg.sender, excessB);
                amountB = amountBOptimal; 
            }

            uint256 liquidityTokens = (amountA * totalLiquidity) / reserveA;
            require(liquidityTokens > 0, "Insufficient liquidity");
            
            reserveA += amountA;
            reserveB += amountB;
            liquidity[msg.sender] += liquidityTokens;
            totalLiquidity += liquidityTokens;
        }
        
        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity[msg.sender]);
    }

    function removeLiquidity(uint256 liquidityTokens) external {
        require(liquidityTokens > 0, "Amount must be positive");
        require(liquidity[msg.sender] >= liquidityTokens, "Insufficient liquidity");
        
        uint256 amountA = (liquidityTokens * reserveA) / totalLiquidity;
        uint256 amountB = (liquidityTokens * reserveB) / totalLiquidity;
        
        reserveA -= amountA;
        reserveB -= amountB;
        
        liquidity[msg.sender] -= liquidityTokens;
        totalLiquidity -= liquidityTokens;
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidityTokens);
    }

    function swap(address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");
        require(amountIn > 0, "Amount must be positive");
        
        bool isAToB = (tokenIn == tokenA);
        (address tokenOut, uint256 reserveIn, uint256 reserveOut) = isAToB ? 
            (tokenB, reserveA, reserveB) : (tokenA, reserveB, reserveA);
        
        uint256 amountInWithFee = amountIn * 997;
        amountOut = (amountInWithFee * reserveOut) / 
                   (reserveIn * 1000 + amountInWithFee);
        
        require(amountOut > 0, "Insufficient output");
        require(amountOut < reserveOut, "Insufficient liquidity");
        
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        
        if (isAToB) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }
        
        IERC20(tokenOut).transfer(msg.sender, amountOut);
        
        emit TokenSwapped(msg.sender, tokenIn, amountIn, tokenOut, amountOut);
        return amountOut;
    }

    function getPrice(address tokenIn, uint256 amountIn) public view returns (uint256) {
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");
        
        bool isAToB = (tokenIn == tokenA);
        (uint256 reserveIn, uint256 reserveOut) = isAToB ? 
            (reserveA, reserveB) : (reserveB, reserveA);
        
        uint256 amountInWithFee = amountIn * 997;
        return (amountInWithFee * reserveOut) / 
               (reserveIn * 1000 + amountInWithFee);
    }

    function sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
}
