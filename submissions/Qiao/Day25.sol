// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AutomatedMarketMaker is ERC20 {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    address public owner;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    // define LP token
    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amount must be greater than zero");

        uint256 liquidity;
        if(totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min(amountA * totalSupply() / reserveA, amountB * totalSupply() / reserveB);
        }
        
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        reserveA += amountA;
        reserveB += amountB;

        _mint(msg.sender, liquidity);
        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut) {
        require(liquidityToRemove > 0, "Invalid amount.");
        require(liquidityToRemove < totalSupply(), "Insufficient liquidity to remove.");
        
        amountAOut = liquidityToRemove * reserveA / totalSupply();
        amountBOut = liquidityToRemove * reserveB / totalSupply();
        
        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves.");
        _burn(msg.sender, liquidityToRemove);
        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);

        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);
        reserveA -= amountAOut;
        reserveB -= amountBOut;
        
        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
        return (amountAOut, amountBOut);
    }

    function swapAforB(uint256 amountAIn, uint256 minBOut) external {
        require(amountAIn > 0, "Invalid amount for trading.");
        require(reserveA * reserveB > 0, "Insufficient reserve.");

        uint256 amountAInAdjusted = amountAIn * 997 / 1000; //charge .3% fee
        uint256 amountBOut = reserveB - reserveA * reserveB / (reserveA + amountAInAdjusted);
        require(amountBOut >= minBOut, "Insufficient output amount.");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAInAdjusted;
        reserveB -= amountBOut;
        emit TokensSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    function swapBforA(uint256 amountBIn, uint256 minAOut) external {
        require(amountBIn > 0, "Invalid amount for trading.");
        require(reserveA * reserveB > 0, "Insufficient reserve.");

        uint256 amountBInAdjusted = amountBIn * 997 / 1000; //charge .3% fee
        uint256 amountAOut = reserveA - reserveA * reserveB / (reserveB + amountBInAdjusted);
        require(amountAOut >= minAOut, "Insufficient output amount.");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBInAdjusted;
        reserveA -= amountAOut;
        emit TokensSwapped(msg.sender, address(tokenA), amountBIn, address(tokenB), amountAOut);

    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
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
