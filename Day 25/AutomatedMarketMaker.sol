// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Automated Market Maker (Uniswap-style)
/// @notice Minimal AMM with liquidity add/remove and swaps

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract AutomatedMarketMaker {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLPSupply;

    mapping(address => uint256) public lpBalance;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swapped(address indexed trader, address tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Add liquidity and receive LP tokens
    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 lpMinted) {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if (totalLPSupply == 0) {
            lpMinted = sqrt(amountA * amountB);
        } else {
            lpMinted = min((amountA * totalLPSupply) / reserveA, (amountB * totalLPSupply) / reserveB);
        }

        lpBalance[msg.sender] += lpMinted;
        totalLPSupply += lpMinted;

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, lpMinted);
    }

    /// @notice Remove liquidity and burn LP tokens
    function removeLiquidity(uint256 lpAmount) external returns (uint256 amountA, uint256 amountB) {
        require(lpAmount > 0 && lpBalance[msg.sender] >= lpAmount, "Invalid LP amount");

        amountA = (lpAmount * reserveA) / totalLPSupply;
        amountB = (lpAmount * reserveB) / totalLPSupply;

        lpBalance[msg.sender] -= lpAmount;
        totalLPSupply -= lpAmount;

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    /// @notice Swap token A for token B
    function swapAforB(uint256 amountAIn) external returns (uint256 amountBOut) {
        require(amountAIn > 0, "Invalid input");
        tokenA.transferFrom(msg.sender, address(this), amountAIn);

        amountBOut = getAmountOut(amountAIn, reserveA, reserveB);
        reserveA += amountAIn;
        reserveB -= amountBOut;

        tokenB.transfer(msg.sender, amountBOut);
        emit Swapped(msg.sender, address(tokenA), amountAIn, amountBOut);
    }

    /// @notice Swap token B for token A
    function swapBforA(uint256 amountBIn) external returns (uint256 amountAOut) {
        require(amountBIn > 0, "Invalid input");
        tokenB.transferFrom(msg.sender, address(this), amountBIn);

        amountAOut = getAmountOut(amountBIn, reserveB, reserveA);
        reserveB += amountBIn;
        reserveA -= amountAOut;

        tokenA.transfer(msg.sender, amountAOut);
        emit Swapped(msg.sender, address(tokenB), amountBIn, amountAOut);
    }

    /// @notice x*y=k pricing formula with 0.3% fee
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn + amountInWithFee;
        return numerator / denominator;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

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
