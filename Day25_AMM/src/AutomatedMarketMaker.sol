// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Simple UniswapV2-style AMM with LP ERC20
/// @notice Constant product (x*y=k), 0.3% fee, LP mint/burn
contract AutomatedMarketMaker is ERC20 {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveA; // tracked reserves (not reading balances each time)
    uint256 public reserveB;

    address public immutable owner;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityBurned);
    event TokensSwapped(
        address indexed trader,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );

    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        require(_tokenA != _tokenB, "same token");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    // ----------- Core AMM -----------

    /// @notice Add liquidity. Deposit both tokens; receive LP tokens.
    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 liquidity) {
        require(amountA > 0 && amountB > 0, "amounts=0");

        // pull tokens in (user must approve beforehand)
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "A transferFrom fail");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "B transferFrom fail");

        if (totalSupply() == 0) {
            // first LP sets price; LP supply = sqrt(A*B)
            liquidity = _sqrt(amountA * amountB);
        } else {
            // mint proportionally (protect against overminting)
            uint256 liqA = (amountA * totalSupply()) / reserveA;
            uint256 liqB = (amountB * totalSupply()) / reserveB;
            liquidity = liqA < liqB ? liqA : liqB;
        }
        require(liquidity > 0, "liquidity=0");

        _mint(msg.sender, liquidity);

        // update tracked reserves
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity and receive both tokens back.
    function removeLiquidity(uint256 liquidityToBurn) external returns (uint256 amountAOut, uint256 amountBOut) {
        require(liquidityToBurn > 0, "liq=0");
        require(balanceOf(msg.sender) >= liquidityToBurn, "not enough LP");

        uint256 ts = totalSupply();
        require(ts > 0, "no liq");

        amountAOut = (liquidityToBurn * reserveA) / ts;
        amountBOut = (liquidityToBurn * reserveB) / ts;
        require(amountAOut > 0 && amountBOut > 0, "dust");

        _burn(msg.sender, liquidityToBurn);

        // update reserves first (checks-effects-interactions)
        reserveA -= amountAOut;
        reserveB -= amountBOut;

        require(tokenA.transfer(msg.sender, amountAOut), "A transfer fail");
        require(tokenB.transfer(msg.sender, amountBOut), "B transfer fail");

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToBurn);
    }

    /// @notice Swap Token A → Token B
    /// @param amountAIn exact amount of A you send
    /// @param minBOut minimum B you expect (slippage guard)
    function swapAforB(uint256 amountAIn, uint256 minBOut) external returns (uint256 amountBOut) {
        require(amountAIn > 0, "amount=0");
        require(reserveA > 0 && reserveB > 0, "no reserves");

        // Pull A in
        require(tokenA.transferFrom(msg.sender, address(this), amountAIn), "A transferFrom fail");

        // 0.3% fee → multiplier 997/1000
        uint256 aInWithFee = (amountAIn * 997) / 1000;
        amountBOut = (reserveB * aInWithFee) / (reserveA + aInWithFee);
        require(amountBOut >= minBOut, "slippage");

        // update reserves before sending out
        reserveA += aInWithFee; // fee stays in pool (benefits LPs)
        reserveB -= amountBOut;

        require(tokenB.transfer(msg.sender, amountBOut), "B transfer fail");

        emit TokensSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    /// @notice Swap Token B → Token A
    function swapBforA(uint256 amountBIn, uint256 minAOut) external returns (uint256 amountAOut) {
        require(amountBIn > 0, "amount=0");
        require(reserveA > 0 && reserveB > 0, "no reserves");

        require(tokenB.transferFrom(msg.sender, address(this), amountBIn), "B transferFrom fail");

        uint256 bInWithFee = (amountBIn * 997) / 1000;
        amountAOut = (reserveA * bInWithFee) / (reserveB + bInWithFee);
        require(amountAOut >= minAOut, "slippage");

        reserveB += bInWithFee;
        reserveA -= amountAOut;

        require(tokenA.transfer(msg.sender, amountAOut), "A transfer fail");

        emit TokensSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }

    /// @notice View current reserves (for UI/quotes)
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    // ----------- Utils -----------
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        uint256 x = (y / 2) + 1;
        z = y;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    }
}
