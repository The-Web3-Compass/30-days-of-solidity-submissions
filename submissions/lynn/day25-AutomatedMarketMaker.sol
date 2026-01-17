//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title 提供代币挖矿及交换的自动交易市场
contract AutomatedMarketMaker is ERC20 {
    address public owner;
    uint256 public marketFeePercent = 30; // in basis points 1% = 100
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed user, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokenSwaped(address indexed user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(
        address _tokenA, 
        address _tokenB, 
        string memory _name, 
        string memory _symbol
    ) ERC20(_name, _symbol) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external payable {
        require(amountA > 0 && amountB > 0, "Amount should be greater than 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 liquidity;
        if (totalSupply() == 0) {
            // 第一个存代币的人决定了池子里tokenA和tokenB的比例
            liquidity = sqrt(amountA * amountB); 
        } else {
            // 存的代币占池子储备的比例，就是得到市场份额（以更小的值为准）
            liquidity = min(amountA * totalSupply() / reserveA, amountB * totalSupply() / reserveB);
        }
        _mint(msg.sender, liquidity);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidityAmount) external returns(uint256 amountAOut, uint256 amountBOut) {
        require(liquidityAmount > 0, "Amount should be greater than 0");
        require(liquidityAmount <= balanceOf(msg.sender), "Insufficient balance");

        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity >= liquidityAmount, "Insufficient liquidity in this pool");

        uint256 amountA = reserveA * liquidityAmount / totalLiquidity;
        uint256 amountB = reserveB * liquidityAmount / totalLiquidity;
        require(amountA > 0 && amountB > 0, "Insufficient reserve for remove liquidity");

        reserveA -= amountA;
        reserveB -= amountB;

        _burn(msg.sender, liquidityAmount);
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidityAmount);

        return (amountA, amountB);
    }

    function swapAforB(uint256 amountAIn, uint256 minBOut) external {
        require(amountAIn > 0, "Amount A should be greater than 0");
        require(reserveB > 0, "Insufficient reserve");

        uint256 amountBOut = caculateBfromA(amountAIn);
        require(amountBOut >= minBOut, "Slippage too high");

        reserveA += amountAIn; // 用扣手续费之前的金额，这样手续费会填充池子储备，给存代币的用户收益
        reserveB -= amountBOut;

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        emit TokenSwaped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    function swapBforA(uint256 amountBIn, uint256 minAOut) external {

        require(amountBIn > 0, "Amount B should be greater than 0");
        require(reserveA > 0, "Insufficient reserve");

        uint256 amountAOut = caculateAfromB(amountBIn);
        require(amountAOut >= minAOut, "Slippage too high");

        reserveB += amountBIn; // 用扣手续费之前的金额，这样手续费会填充池子储备，给存代币的用户收益
        reserveA -= amountAOut;

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        emit TokenSwaped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);

    }

    function getReserve() external view returns(uint256, uint256) {
        return (reserveA, reserveB);
    }

    function caculateAfromB(uint256 amountB) public view returns(uint256) {

        require(amountB > 0, "Amount should be greater than 0");
        uint256 amountBWithFee = amountB * (10000 - marketFeePercent) / 10000;
        // amountA占池子比例和amountB一样
        return (reserveA * amountBWithFee / (amountBWithFee + reserveB));
    }

    function caculateBfromA(uint256 amountA) public view returns(uint256) {

        require(amountA > 0, "Amount should be greater than 0");
        uint256 amountAWithFee = amountA * (10000 - marketFeePercent) / 10000;
        // amountA占池子比例和amountB一样
        return (reserveB * amountAWithFee / (amountAWithFee + reserveA));
    }

    // Babylonian 平方根算法
    function sqrt(uint256 number) internal pure returns(uint256 result) {
        if (number > 3) {
            result = number;
            uint256 x = number / 2 +1;
            while (x < result) {
                result = x;
                x = (number / x + x) / 2;
            }
        } else if (number != 0) {
            result = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }

}