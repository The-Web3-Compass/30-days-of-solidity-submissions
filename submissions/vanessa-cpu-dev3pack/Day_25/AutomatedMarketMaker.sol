// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AutomatedMarketMaker is ERC20 {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;

    constructor(address _tokenA, address _tokenB, string memory name, string memory symbol) ERC20(name, symbol) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        uint256 liquidity;
        if (totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min(
                (amountA * totalSupply()) / reserveA,
                (amountB * totalSupply()) / reserveB
            );
        }
        
        _mint(msg.sender, liquidity);
        reserveA += amountA;
        reserveB += amountB;
    }

    function swapAforB(uint256 amountAIn) external {
        // 1. Calculate price
        // Input with 0.3% fee
        uint256 amountAInWithFee = (amountAIn * 997) / 1000;
        
        // Calculate amount out (y = k / x)
        // (reserveA + amountIn) * (reserveB - amountOut) = k
        uint256 amountBOut = (reserveB * amountAInWithFee) / (reserveA + amountAInWithFee);

        // 2. Transfer Tokens
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        // 3. Update Reserves
        reserveA += amountAIn; // Note: Reserves track raw balance, so we add full amount (fee included in pool)
        reserveB -= amountBOut;
    }

    // Math Helpers
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) { z = x; x = (y / x + x) / 2; }
        } else if (y != 0) { z = 1; }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) { return a < b ? a : b; }
}