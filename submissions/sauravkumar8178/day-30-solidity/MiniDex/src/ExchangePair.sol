// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

/// @notice ExchangePair: simple constant-product AMM pair for tokenA/tokenB
contract ExchangePair is ERC20 {
    IERC20Minimal public token0;
    IERC20Minimal public token1;

    uint112 private reserve0; // uses single-slot packing
    uint112 private reserve1;

    uint32 private blockTimestampLast;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    uint256 public constant FEE_NUM = 3;    // 0.3% => fee numerator
    uint256 public constant FEE_DEN = 1000;

    constructor(address _token0, address _token1) ERC20("Simple LP", "sLP") {
        require(_token0 != _token1, "IDENTICAL");
        token0 = IERC20Minimal(_token0);
        token1 = IERC20Minimal(_token1);
    }

    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    // internal sync after transfers
    function _updateReserves(uint256 balance0, uint256 balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "OVERFLOW");
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp % 2**32);
        emit Sync(reserve0, reserve1);
    }

    /// @notice Add liquidity by transferring tokens to pair and calling mint
    function mint(address to) external returns (uint256 liquidity) {
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        if (totalSupply == 0) {
            liquidity = _sqrt(amount0 * amount1);
            require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
            _mint(to, liquidity);
        } else {
            uint256 liquidity0 = (amount0 * totalSupply) / reserve0;
            uint256 liquidity1 = (amount1 * totalSupply) / reserve1;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
            _mint(to, liquidity);
        }

        _updateReserves(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1, liquidity);
    }

    /// @notice Remove liquidity by burning LP tokens from caller
    function burn(address to) external returns (uint256 amount0, uint256 amount1) {
        uint256 _totalSupply = totalSupply;
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        uint256 liquidity = balanceOf[msg.sender];
        require(liquidity > 0, "NO_LIQUIDITY");

        // transfer LP tokens to this contract and burn (caller must approve this contract)
        // But our LP token is internal (same contract). So we simply _burn from caller.
        _burn(msg.sender, liquidity);

        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");

        // transfer underlying tokens to recipient
        require(token0.transfer(to, amount0), "TRANSFER_FAIL0");
        require(token1.transfer(to, amount1), "TRANSFER_FAIL1");

        balance0 = token0.balanceOf(address(this));
        balance1 = token1.balanceOf(address(this));
        _updateReserves(balance0, balance1);
        emit Burn(msg.sender, to, amount0, amount1, liquidity);
    }

    /// @notice Swap tokens. Provide amount0Out or amount1Out > 0 and send corresponding in amount.
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) require(token0.transfer(to, amount0Out), "TRANSFER_FAIL0");
        if (amount1Out > 0) require(token1.transfer(to, amount1Out), "TRANSFER_FAIL1");

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        uint256 amount0In = 0;
        uint256 amount1In = 0;
        if (balance0 > _reserve0 - amount0Out) amount0In = balance0 - (_reserve0 - amount0Out);
        if (balance1 > _reserve1 - amount1Out) amount1In = balance1 - (_reserve1 - amount1Out);

        require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");

        // apply fee: multiply balances by 1000 - fee*? pattern to check k'
        uint256 balance0Adjusted = (balance0 * (FEE_DEN)) - (amount0In * FEE_NUM);
        uint256 balance1Adjusted = (balance1 * (FEE_DEN)) - (amount1In * FEE_NUM);

        // Ensure: (balance0Adjusted * balance1Adjusted) >= (reserve0 * reserve1 * FEE_DEN^2)
        uint256 left = balance0Adjusted * balance1Adjusted;
        uint256 right = uint256(_reserve0) * uint256(_reserve1) * (FEE_DEN ** 2);

        require(left >= right, "K");
        _updateReserves(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // ---------- helpers ----------
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        uint256 x = y / 2 + 1;
        z = y;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    }
}
