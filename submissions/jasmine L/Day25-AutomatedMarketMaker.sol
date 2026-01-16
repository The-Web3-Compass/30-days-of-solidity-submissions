// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AutomatedMarketMaker is ERC20{
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    address public owner;
    //添加流动性，获得了多少LP代币
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    // 移除流动性，销毁了多少LP代币
    event LiquidityRemoved(address indexed provider,  uint256 amountA, uint256 amountB, uint256 liquidity);
    // 兑换代币
    event Tokenswapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);


    

    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol)ERC20(_name,_symbol){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);

        owner = msg.sender;
    }
}