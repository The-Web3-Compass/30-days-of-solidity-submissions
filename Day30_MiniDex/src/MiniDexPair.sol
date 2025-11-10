// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MiniDexPair is ReentrancyGuard {
    address public immutable tokenA;
    address public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLPSupply;

    mapping(address => uint256) public lpBalances;

    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 lpMinted,
        uint256 poolShare
    );

    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 lpBurned
    );

    event Swapped(
        address indexed user,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 outputAmount
    );

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "Identical tokens");
        require(_tokenA != address(0) && _tokenB != address(0), "Zero address");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // Utilities
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = (y / 2) + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _updateReserves() private {
        reserveA = IERC20(tokenA).balanceOf(address(this));
        reserveB = IERC20(tokenB).balanceOf(address(this));
    }

    // Add Liquidity
    function addLiquidity(uint256 amountA, uint256 amountB)
        external
        nonReentrant
    {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 lpMint;
        if (totalLPSupply == 0) {
            lpMint = sqrt(amountA * amountB);
        } else {
            lpMint = min(
                (amountA * totalLPSupply) / reserveA,
                (amountB * totalLPSupply) / reserveB
            );
        }
        require(lpMint > 0, "Zero LP minted");

        lpBalances[msg.sender] += lpMint;
        totalLPSupply += lpMint;

        _updateReserves();

        uint256 share = (lpBalances[msg.sender] * 1e18) / totalLPSupply;

        emit LiquidityAdded(msg.sender, amountA, amountB, lpMint, share);
    }

    // Remove Liquidity
    function removeLiquidity(uint256 lpAmount)
        external
        nonReentrant
    {
        require(lpAmount > 0 && lpAmount <= lpBalances[msg.sender], "Invalid LP");

        uint256 amountA = (lpAmount * reserveA) / totalLPSupply;
        uint256 amountB = (lpAmount * reserveB) / totalLPSupply;

        lpBalances[msg.sender] -= lpAmount;
        totalLPSupply -= lpAmount;

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        _updateReserves();

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    // Calculate Swap Output
    function getAmountOut(uint256 input, address inputToken)
        public
        view
        returns (uint256)
    {
        require(inputToken == tokenA || inputToken == tokenB, "Invalid token");

        bool isA = inputToken == tokenA;
        (uint256 inRes, uint256 outRes) = isA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);

        uint256 inputWithFee = input * 997;
        uint256 numerator = inputWithFee * outRes;
        uint256 denominator = (inRes * 1000) + inputWithFee;

        return numerator / denominator;
    }

    // Swap with min output + deadline
    function swap(
        uint256 inputAmount,
        address inputToken,
        uint256 minOutput,
        uint256 deadline
    )
        external
        nonReentrant
    {
        require(block.timestamp <= deadline, "Expired");
        require(inputAmount > 0, "Zero input");

        address outputToken = inputToken == tokenA ? tokenB : tokenA;
        uint256 outputAmount = getAmountOut(inputAmount, inputToken);
        require(outputAmount >= minOutput, "Slippage exceeded");

        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        IERC20(outputToken).transfer(msg.sender, outputAmount);

        _updateReserves();

        emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);
    }

    // View Functions
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getLPBalance(address user) external view returns (uint256) {
        return lpBalances[user];
    }

    function getTotalLPSupply() external view returns (uint256) {
        return totalLPSupply;
    }
}
