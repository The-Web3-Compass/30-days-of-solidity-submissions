// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AutomatedMarketMaker is ERC20 {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;

    // these are for price oracles (time-weighted average price (TWAP) tracks price over time, 
    // making manipulation expensive)
    uint256 public priceACumulativeLast;
    uint256 public priceBCumulativeLast;
    uint256 public lastTimestamp;

    // these are for flash loan protection
    // record reserve at the start of the transaction & verify they haven't been drained by the end
    uint256 private _reserveABefore;
    uint256 private _reserveBBefore;
    bool private _locked;

    
    // this function is for price oracles (to update the stated variables on every swap)
    function _updateOracle() internal {
        uint256 timeElapsed= block.timestamp - lastTimestamp;
        if (timeElapsed > 0 && reserveA > 0 && reserveB > 0) {
            // accumulate price * time
            priceACumulativeLast += (reserveB / reserveA) * timeElapsed;
            priceBCumulativeLast += (reserveA / reserveB) * timeElapsed;
            lastTimestamp = block.timestamp;
        }
    }

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

    modifier notExpired(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction expired");
        _;
    }
    
    modifier flashLoanGuard() { // protecting AGAINST flash loans is funny since we learned TO do them yesterday
            require(!_locked, "No flash loans");
        _locked = true;
        _reserveABefore = reserveA;
        _reserveBBefore = reserveB;
        _;
        // k must be at least as large after the transaction
        require(
            reserveA * reserveB >= _reserveABefore * _reserveBBefore, "K invariant violated"
        );
        _locked = false;
    }

    function swapAforB(uint256 amountAIn, uint256 minAmountBOut, uint256 deadline) external notExpired(deadline) flashLoanGuard {
        _updateOracle();

        // 1. calculate the price
        // input with 0.3% fee
        uint256 amountAInWithFee = (amountAIn * 997) / 1000;

        // calculate amount out (y = k / x)
        // (reserveA + amountIn) * reserveB - amountOut) = k
        uint256 amountBOut = (reserveB * amountAInWithFee) / (reserveA + amountAInWithFee);

        require(amountBOut >= minAmountBOut, "Slippage too high");         

        // 2. transfer tokens
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        // 3. update reserve
        reserveA += amountAIn; // note: reserves track raw balance, so we add full amount (fee included in pool)
        reserveB -= amountBOut;
    }

    // math helpers
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) { z = x; x = (y / x + x) / 2; }
        } else if (y != 0) { z = 1; }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) { return a < b ? a : b; }

    function removeLiquidity(uint256 liquidity) external { 
        uint256 supply = totalSupply();

        // calculate their share of each reserve
        uint256 amountA = (liquidity * reserveA) / supply;
        uint256 amountB = (liquidity * reserveB) / supply;

        require(amountA > 0 && amountB > 0, "Insufficient liquidity");

        // burn their LP tokens first (CEI pattern)
        _burn(msg.sender, liquidity);
        reserveA -= amountA;
        reserveB -= amountB;

        // then send tokens back
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }
}