// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract AutomatedMarketMaker is ERC20 {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    address public owner;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external{
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");
        //transferFrom(address from, address to, uint256 amount) external returns (bool);
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 liquidity;
        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            liquidity = Math.min(
                amountA * totalSupply() / reserveA,
                amountB * totalSupply() / reserveB
            );
        }

        _mint(msg.sender, liquidity);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut){
        require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
        require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");
        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");

        amountAOut = liquidityToRemove * reserveA / totalLiquidity;
        amountBOut = liquidityToRemove * reserveB / totalLiquidity;

        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");

        reserveA -= amountAOut;
        reserveB -= amountBOut;

        _burn(msg.sender, liquidityToRemove);

        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
        return (amountAOut, amountBOut);
    }

    function swap(bool isAtoB, uint256 amountIn, uint256 minOut) external {
        require(amountIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountInWithFee = amountIn * 997 / 1000;
        uint256 amountOut;
        uint256 reserveIn;
        uint256 reserveOut;
        if (isAtoB) {
            reserveIn = reserveA;
            reserveOut = reserveB;
            amountOut = reserveOut * amountInWithFee / (reserveIn + amountInWithFee);
            require(amountOut >= minOut, "Slippage too high");
            tokenA.transferFrom(msg.sender, address(this), amountIn);
            tokenB.transfer(msg.sender, amountOut); 
            reserveA += amountIn;                       
            reserveB -= amountOut;                                   
            emit TokensSwapped(msg.sender, address(tokenA), amountIn, address(tokenB), amountOut);
        } else {
            reserveIn = reserveB;
            reserveOut = reserveA;
            amountOut = reserveOut * amountInWithFee / (reserveIn + amountInWithFee);
            require(amountOut >= minOut, "Slippage too high");
            tokenB.transferFrom(msg.sender, address(this), amountIn);
            tokenA.transfer(msg.sender, amountOut);
            reserveB += amountIn;
            reserveA -= amountOut;
            emit TokensSwapped(msg.sender, address(tokenB), amountIn, address(tokenA), amountOut);
        }
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
}
