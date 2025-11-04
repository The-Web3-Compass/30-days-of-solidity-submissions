//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AMM
 * @author Eric (https://github.com/0xxEric)
 * @notice A AutomatedMarketMaker
 * @custom:project 30-days-of-solidity-submissions: Day25
 */

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

/// @notice Extremely simplified constant-product AMM for educational purposes.
/// - No fees (or a fixed fee param easily addable)
/// - Single pair (token0 / token1)
contract SimpleAMM is ERC20 {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public constant Fee_bps=500; //fee:5%
    uint256 public constant Fee_denominator=10000;

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    constructor(address _token0, address _token1) ERC20("LP Token", "sLP") {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /// @notice Add liquidity. Caller must approve tokens beforehand.
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 lpMinted) {
        require(amount0 > 0 && amount1 > 0, "zero");
        // transfer tokens in
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        // compute lp to mint
        if (totalSupply() == 0) {
            lpMinted = Math.sqrt(amount0 * amount1);
            _mint(msg.sender, lpMinted);
        } else {
            // proportional
            uint256 lp0 = (amount0 * totalSupply()) / reserve0;
            uint256 lp1 = (amount1 * totalSupply()) / reserve1;
            lpMinted = lp0 < lp1 ? lp0 : lp1;
            require(lpMinted > 0, "insufficient");
            _mint(msg.sender, lpMinted);
        }

        // update reserves
        reserve0 += amount0;
        reserve1 += amount1;
    }

    /// @notice Remove liquidity (burn LP -> withdraw underlying)
    function removeLiquidity(uint256 lpAmount) external returns (uint256 out0, uint256 out1) {
        require(lpAmount > 0 && lpAmount <= balanceOf(msg.sender), "bad lp");
        uint256 _total = totalSupply();
        out0 = (reserve0 * lpAmount) / _total;
        out1 = (reserve1 * lpAmount) / _total;
        _burn(msg.sender, lpAmount);

        reserve0 -= out0;
        reserve1 -= out1;

        token0.transfer(msg.sender, out0);
        token1.transfer(msg.sender, out1);
    }

    /// @notice Swap exact token0 -> token1. Returns amountOut
    function swap0To1(uint256 amount0In, uint256 minAmount1Out) external returns (uint256 amount1Out) {
        require(amount0In > 0, "zero in");
        token0.transferFrom(msg.sender, address(this), amount0In);

        // constant product: (reserve0 + dx) * (reserve1 - dy) >= reserve0 * reserve1
        // with fees//dy = reserve1 - (reserve0 * reserve1) / (reserve0 + dx)

        uint256 feeAmount=amount0In*Fee_bps/Fee_denominator;
        uint256 amount0InAfterFee=amount0In-feeAmount;

        uint256 newReserve0 = reserve0 + amount0InAfterFee;
        uint256 newReserve1 = (reserve0 * reserve1) / newReserve0;
        amount1Out = reserve1 - newReserve1;
        require(amount1Out >= minAmount1Out, "slippage");

        // update reserves
        reserve0 = reserve0+amount0In;
        reserve1 = newReserve1;

        token1.transfer(msg.sender, amount1Out);

        emit Swap(msg.sender,amount0In,0,0,amount1Out,msg.sender);
    }

    /// @notice Swap exact token1 -> token0.
    function swap1To0(uint256 amount1In, uint256 minAmount0Out) external returns (uint256 amount0Out) {
        require(amount1In > 0, "zero in");
        token1.transferFrom(msg.sender, address(this), amount1In);

        uint256 newReserve1 = reserve1 + amount1In;
        uint256 newReserve0 = (reserve0 * reserve1) / newReserve1;
        amount0Out = reserve0 - newReserve0;
        require(amount0Out >= minAmount0Out, "slippage");

        reserve1 = newReserve1;
        reserve0 = newReserve0;

        token0.transfer(msg.sender, amount0Out);
    }
}
