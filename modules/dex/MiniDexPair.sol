// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title  MiniDexPair
/// @author rainwaters11 — Day 30: The Final Build (Mini DEX)
/// @notice Automated Market Maker pair contract implementing the
///         constant-product invariant  x · y ≥ k.
///
/// @dev    LP shares are represented as ERC-20 tokens minted to
///         liquidity providers.  A 0.3 % swap fee is levied on every
///         trade (matching the original Uniswap v2 fee tier).
///
///         Deployers should use MiniDexFactory.createPair() rather
///         than constructing this contract directly.
contract MiniDexPair is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─── Constants ────────────────────────────────────────────────────────────

    /// @notice Minimum liquidity permanently locked on first deposit to
    ///         prevent the LP-token price from becoming manipulable at
    ///         near-zero supply.
    uint256 public constant MINIMUM_LIQUIDITY = 1_000;

    /// @notice Fee numerator (0.3 %).  Denominator is FEE_DENOMINATOR.
    uint256 public constant FEE_NUMERATOR = 997;

    /// @notice Fee denominator.  Fee = 1 - 997/1000 = 0.003 (0.3 %).
    uint256 public constant FEE_DENOMINATOR = 1_000;

    // ─── Immutables ───────────────────────────────────────────────────────────

    /// @notice The factory that deployed this pair.
    address public immutable factory;

    /// @notice Lower-address token in the pair (token0 < token1).
    address public immutable token0;

    /// @notice Higher-address token in the pair.
    address public immutable token1;

    // ─── State ────────────────────────────────────────────────────────────────

    /// @dev Reserve of token0, updated after every liquidity event or swap.
    uint112 private reserve0;

    /// @dev Reserve of token1.
    uint112 private reserve1;

    // ─── Events ───────────────────────────────────────────────────────────────

    event Mint(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to,
        uint256 liquidity
    );

    /// @notice Emitted on every swap.
    /// @param sender       Address that called swap().
    /// @param amount0In    Tokens of token0 sent INTO the pool.
    /// @param amount1In    Tokens of token1 sent INTO the pool.
    /// @param amount0Out   Tokens of token0 sent OUT of the pool.
    /// @param amount1Out   Tokens of token1 sent OUT of the pool.
    /// @param to           Recipient of the output tokens.
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error InsufficientLiquidity();
    error InsufficientInputAmount();
    error InsufficientOutputAmount();
    error InvalidRecipient();
    error InvariantViolated();          // x·y < k after swap
    error InsufficientLiquidityBurned();
    error Overflow();

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _token0  Lower-address token (must be < _token1).
    /// @param _token1  Higher-address token.
    constructor(address _token0, address _token1)
        ERC20("MiniDex LP", "MLP")
    {
        factory = msg.sender;
        token0  = _token0;
        token1  = _token1;
    }

    // ─── View helpers ─────────────────────────────────────────────────────────

    /// @notice Returns the current on-chain reserves.
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    // ─── Liquidity provision ──────────────────────────────────────────────────

    /// @notice Deposit token0 and token1 to receive LP shares.
    ///
    /// @dev    Caller must pre-approve this contract for at least
    ///         `amount0Desired` and `amount1Desired`.
    ///
    ///         ⚠️  SEED LIQUIDITY — The FIRST depositor permanently sets the
    ///         market price for this pair.  Depositing 100 WATERS + 1 ETH
    ///         creates a 100:1 price; depositing 1 WATERS + 1 ETH creates 1:1.
    ///         As the token founder you should be the first caller so you can
    ///         seed the pool at your intended valuation before anyone else
    ///         can trade or provide liquidity at an adverse ratio.
    ///
    ///         On the FIRST deposit the deposited amounts define the
    ///         initial price; LP shares issued equal √(x·y) − MINIMUM_LIQUIDITY.
    ///
    ///         On subsequent deposits the effective amounts are capped to
    ///         maintain the current pool ratio.
    ///
    /// @param amount0Desired   Max token0 to deposit.
    /// @param amount1Desired   Max token1 to deposit.
    /// @param to               Address that receives the LP tokens.
    /// @return liquidity       LP tokens minted.
    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        address to
    ) external nonReentrant returns (uint256 liquidity) {
        if (to == address(0)) revert InvalidRecipient();

        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        uint256 totalSupply_ = totalSupply();

        uint256 amount0;
        uint256 amount1;

        if (totalSupply_ == 0) {
            // First deposit — both full amounts are accepted.
            amount0 = amount0Desired;
            amount1 = amount1Desired;
        } else {
            // Subsequent deposits — preserve the existing x/y ratio.
            uint256 amount1Optimal = (amount0Desired * _reserve1) / _reserve0;
            if (amount1Optimal <= amount1Desired) {
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                uint256 amount0Optimal = (amount1Desired * _reserve0) / _reserve1;
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }
        }

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidity();

        // Pull tokens from caller.
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        // Compute LP shares to mint.
        if (totalSupply_ == 0) {
            // Geometric mean of deposits, minus the permanently locked minimum.
            uint256 geomMean = _sqrt(amount0 * amount1);
            if (geomMean <= MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
            liquidity = geomMean - MINIMUM_LIQUIDITY;

            // Lock MINIMUM_LIQUIDITY to address(1) permanently.
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            // Pro-rata share: min(amount0/reserve0, amount1/reserve1) * totalSupply.
            uint256 liq0 = (amount0 * totalSupply_) / _reserve0;
            uint256 liq1 = (amount1 * totalSupply_) / _reserve1;
            liquidity = liq0 < liq1 ? liq0 : liq1;
        }

        if (liquidity == 0) revert InsufficientLiquidity();
        _mint(to, liquidity);

        _updateReserves();
        emit Mint(msg.sender, amount0, amount1, liquidity);
    }

    /// @notice Burn LP tokens to reclaim the underlying token0 and token1.
    ///
    /// @param liquidity    Amount of LP tokens to burn (must be pre-transferred
    ///                     to this contract before calling, or use
    ///                     `transfer + removeLiquidity` in one tx via a router).
    /// @param to           Recipient of the redeemed tokens.
    /// @return amount0     token0 returned.
    /// @return amount1     token1 returned.
    function removeLiquidity(uint256 liquidity, address to)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        if (to == address(0)) revert InvalidRecipient();
        if (liquidity == 0)   revert InsufficientLiquidityBurned();

        uint256 totalSupply_ = totalSupply();
        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));

        // Pro-rata share of pool balances.
        amount0 = (liquidity * bal0) / totalSupply_;
        amount1 = (liquidity * bal1) / totalSupply_;

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        // Burn LP tokens from this contract (caller must transfer them here first).
        _burn(address(this), liquidity);

        IERC20(token0).safeTransfer(to, amount0);
        IERC20(token1).safeTransfer(to, amount1);

        _updateReserves();
        emit Burn(msg.sender, amount0, amount1, to, liquidity);
    }

    // ─── Swapping ─────────────────────────────────────────────────────────────

    /// @notice Swap an exact input amount of one token for as many of the
    ///         other token as possible, subject to the x · y ≥ k invariant.
    ///
    /// @dev    SECURITY — The invariant check is performed AFTER the output
    ///         transfer so that flash-swap patterns remain possible, yet the
    ///         pool is protected:
    ///
    ///           (reserve0 + amountIn_fee) · (reserve1 − amountOut) ≥ k
    ///
    ///         Where  amountIn_fee = amountIn * FEE_NUMERATOR / FEE_DENOMINATOR
    ///         (i.e. the 0.3 % fee is kept inside the pool, growing k over time).
    ///
    /// @param amountIn     Exact amount of `tokenIn` to sell.
    /// @param tokenIn      Address of the token being sold (must be token0 or token1).
    /// @param to           Recipient of the bought tokens.
    /// @return amountOut   Amount of the other token received.
    function swap(
        uint256 amountIn,
        address tokenIn,
        address to
    ) external nonReentrant returns (uint256 amountOut) {
        // ── Input validation ──────────────────────────────────────────────────
        if (amountIn == 0)    revert InsufficientInputAmount();
        if (to == address(0)) revert InvalidRecipient();

        bool zeroForOne = tokenIn == token0;
        if (!zeroForOne && tokenIn != token1) revert InsufficientInputAmount();

        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        if (_reserve0 == 0 || _reserve1 == 0) revert InsufficientLiquidity();

        // ── Determine in/out tokens and reserves ──────────────────────────────
        (
            address tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = zeroForOne
            ? (token1, uint256(_reserve0), uint256(_reserve1))
            : (token0, uint256(_reserve1), uint256(_reserve0));

        // ── Pull input tokens from caller ─────────────────────────────────────
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // ── Compute amountOut using the constant-product formula with fee ──────
        //
        //   Derivation:
        //     k          = reserveIn  · reserveOut
        //     newIn      = reserveIn  + amountIn · (FEE_NUM / FEE_DEN)
        //     newOut     = k / newIn
        //     amountOut  = reserveOut − newOut
        //
        //   Rearranged to avoid division by k and keep precision:
        //     amountOut = (amountIn · FEE_NUM · reserveOut)
        //                 / (reserveIn · FEE_DEN + amountIn · FEE_NUM)
        //
        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        uint256 numerator       = amountInWithFee * reserveOut;
        uint256 denominator     = (reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        amountOut               = numerator / denominator;

        if (amountOut == 0)           revert InsufficientOutputAmount();
        if (amountOut >= reserveOut)  revert InsufficientLiquidity();

        // ── Transfer output tokens to recipient ───────────────────────────────
        IERC20(tokenOut).safeTransfer(to, amountOut);

        // ── Post-transfer x · y ≥ k check ────────────────────────────────────
        //
        //   After the swap the pool holds:
        //     newBalance0 = token0.balanceOf(this)
        //     newBalance1 = token1.balanceOf(this)
        //
        //   We verify:  newBalance0 · newBalance1 ≥ reserve0 · reserve1
        //
        //   This is the core AMM invariant.  Using actual balances (not
        //   computed reserves) also catches any tokens accidentally sent
        //   to the contract outside of a swap call.
        //
        uint256 newBalance0 = IERC20(token0).balanceOf(address(this));
        uint256 newBalance1 = IERC20(token1).balanceOf(address(this));
        uint256 k           = uint256(_reserve0) * uint256(_reserve1);

        // ── ⚠️  INVARIANT ENFORCEMENT ─────────────────────────────────────────
        //   The product of the new balances must be at least equal to k.
        //   Failure here means the swap would drain the pool below the
        //   original constant product — this is the critical safety check.
        if (newBalance0 * newBalance1 < k) revert InvariantViolated();

        // ── Update on-chain reserves ──────────────────────────────────────────
        _updateReserves();

        // ── Emit ─────────────────────────────────────────────────────────────
        // Pre-compute event fields to avoid stack-too-deep from inline ternaries.
        uint256 ev0In  = zeroForOne ? amountIn  : 0;
        uint256 ev1In  = zeroForOne ? 0          : amountIn;
        uint256 ev0Out = zeroForOne ? 0          : amountOut;
        uint256 ev1Out = zeroForOne ? amountOut  : 0;
        emit Swap(msg.sender, ev0In, ev1In, ev0Out, ev1Out, to);
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────

    /// @dev Sync on-chain reserves to actual ERC-20 balances.
    function _updateReserves() internal {
        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));

        if (bal0 > type(uint112).max || bal1 > type(uint112).max) revert Overflow();

        reserve0 = uint112(bal0);
        reserve1 = uint112(bal1);

        emit Sync(reserve0, reserve1);
    }

    /// @dev Babylonian square-root (integer, rounds down).
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
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
