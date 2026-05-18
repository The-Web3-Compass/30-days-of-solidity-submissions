// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title  AutomatedMarketMaker — MistySwap 🌊
/// @author rainwaters11 — Day 25: Automated Market Maker (AMM)
/// @notice A self-contained, teaching-focused AMM implementing the
///         constant-product formula  x · y = k  for a $WATERS / tokenB pair.
///
///         LP providers deposit both tokens and receive ERC-20 LP Tokens
///         representing their proportional share of the pool.  A 0.3 % swap
///         fee is retained in the pool on every trade, growing k over time
///         and rewarding long-term liquidity providers.
///
/// @dev    THE CONSTANT-PRODUCT FORMULA  x · y = k
///         ┌──────────────────────────────────────────────────────────────┐
///         │  x = reserveA  (e.g. $WATERS)                               │
///         │  y = reserveB  (e.g. stablecoin / WETH)                     │
///         │  k = x · y  (the invariant — must never decrease)           │
///         │                                                              │
///         │  When a user swaps ΔA of tokenA IN:                         │
///         │    new_x = x + ΔA                                           │
///         │    new_y = k / new_x     ← solve for new y                  │
///         │    ΔB    = y − new_y     ← tokens OUT                       │
///         │                                                              │
///         │  PRICE DISCOVERY:                                            │
///         │  Each swap changes the ratio x/y, which IS the price.       │
///         │  No oracle needed — price emerges naturally from trading.    │
///         │                                                              │
///         │  SLIPPAGE:                                                   │
///         │  A large swap (e.g. buying 90 % of the pool) moves the      │
///         │  price dramatically.  This "drag" protects the pool from     │
///         │  being drained in a single transaction.                      │
///         └──────────────────────────────────────────────────────────────┘
///
///         0.3 % FEE — HOW IT REWARDS LIQUIDITY PROVIDERS
///         ┌──────────────────────────────────────────────────────────────┐
///         │  Instead of using 100 % of the input for the k calculation, │
///         │  we use only 99.7 % (997/1000).  The 0.3 % stays in the    │
///         │  pool, growing the product k = x·y over time.               │
///         │                                                              │
///         │  When an LP later withdraws, they receive their pro-rata     │
///         │  share of the larger pool → they earned the accumulated fees.│
///         │                                                              │
///         │  Formula (rearranged to stay integer-safe):                  │
///         │    amountOut = (amountIn × 997 × reserveOut)                │
///         │                / (reserveIn × 1000 + amountIn × 997)        │
///         └──────────────────────────────────────────────────────────────┘
///
///         LP TOKEN LOGIC
///         ┌──────────────────────────────────────────────────────────────┐
///         │  First deposit   → LP = sqrt(amountA × amountB)             │
///         │                    (geometric mean — fair to both sides)     │
///         │  Later deposits  → LP = min(                                 │
///         │                       amountA / reserveA,                   │
///         │                       amountB / reserveB    ) × totalSupply  │
///         │                    (pro-rata — preserves existing LP value)  │
///         │                                                              │
///         │  The `min` helper prevents a liquidity provider from gaming  │
///         │  the pool by depositing mostly the cheaper token.            │
///         └──────────────────────────────────────────────────────────────┘
///
///         USE CASES IN MISTYCOIN-CORE
///         • $WATERS holders swap tokens without a centralised exchange.
///         • Community members earn fees by providing liquidity.
///         • Day 23 SimpleLending uses pool price for collateral valuation.
///         • Day 24 MultiSig treasury can hold and redeem LP tokens.
contract AutomatedMarketMaker is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─── Constants ────────────────────────────────────────────────────────────

    /// @notice Minimum LP tokens permanently burned on first deposit.
    ///         Prevents price-per-LP-token manipulation at near-zero supply.
    ///         (Uniswap v2 technique — lock 1000 wei of LP to address(0).)
    uint256 public constant MINIMUM_LIQUIDITY = 1_000;

    /// @notice Fee numerator: 997 out of 1000 = 0.3% fee kept in pool.
    uint256 public constant FEE_NUMERATOR = 997;

    /// @notice Fee denominator.
    uint256 public constant FEE_DENOMINATOR = 1_000;

    // ─── Immutables ───────────────────────────────────────────────────────────

    /// @notice Token A in the pair — intended to be $WATERS.
    IERC20 public immutable tokenA;

    /// @notice Token B in the pair — intended to be a stablecoin or WETH.
    IERC20 public immutable tokenB;

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice Current reserve of tokenA held in this contract.
    uint256 public reserveA;

    /// @notice Current reserve of tokenB held in this contract.
    uint256 public reserveB;

    // ─── Events ───────────────────────────────────────────────────────────────

    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 lpTokensMinted
    );

    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 lpTokensBurned
    );

    /// @notice Emitted on every A→B swap.
    event SwapAforB(
        address indexed trader,
        uint256 amountAIn,
        uint256 amountBOut
    );

    /// @notice Emitted on every B→A swap.
    event SwapBforA(
        address indexed trader,
        uint256 amountBIn,
        uint256 amountAOut
    );

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ZeroAmount();
    error ZeroLiquidity();
    error InsufficientLiquidity();       // pool reserves are empty
    error InvariantViolated();           // x·y decreased after swap
    error InsufficientOutputAmount();    // swap would yield 0 tokens out
    error InsufficientABalance();        // LP withdrew more A than available
    error InsufficientBBalance();        // LP withdrew more B than available
    error InvalidToken();

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @notice Deploy MistySwap for a specific token pair.
    ///
    /// @param _tokenA  Address of token A (e.g. $WATERS ERC-20).
    /// @param _tokenB  Address of token B (e.g. stablecoin / WETH ERC-20).
    constructor(address _tokenA, address _tokenB)
        ERC20("MistySwap LP Token", "MSLP")
    {
        require(_tokenA != address(0) && _tokenB != address(0), "AMM: zero address");
        require(_tokenA != _tokenB, "AMM: identical tokens");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // ─── Liquidity: Add ───────────────────────────────────────────────────────

    /// @notice Deposit tokenA and tokenB to receive LP Tokens.
    ///
    /// @dev    LP TOKEN MATH — two cases:
    ///
    ///         CASE 1 — First deposit (pool is empty):
    ///           LP minted = sqrt(amountA × amountB) − MINIMUM_LIQUIDITY
    ///
    ///           WHY sqrt?  It's the geometric mean — fair regardless of
    ///           whether you deposit mostly A or mostly B.  The geometric
    ///           mean also has the property that sqrt(x·y) = sqrt(k), which
    ///           ties LP token supply directly to the pool invariant.
    ///
    ///           MINIMUM_LIQUIDITY (1000) is minted to address(0) and locked
    ///           forever.  This makes the "LP price" (pool value / LP supply)
    ///           immune to manipulation via tiny first deposits.
    ///
    ///         CASE 2 — Subsequent deposits:
    ///           LP minted = min(
    ///               amountA × totalSupply / reserveA,
    ///               amountB × totalSupply / reserveB
    ///           )
    ///
    ///           WHY min?  The smaller ratio is the binding constraint.
    ///           If you deposit too much of one asset the excess is NOT
    ///           refunded automatically here — callers should compute the
    ///           correct ratio off-chain before calling. The `min` prevents
    ///           over-minting LP tokens relative to actual contribution.
    ///
    /// @param amountA      tokenA to deposit (must be pre-approved).
    /// @param amountB      tokenB to deposit (must be pre-approved).
    /// @return lpMinted    LP Tokens received.
    function addLiquidity(uint256 amountA, uint256 amountB)
        external
        nonReentrant
        returns (uint256 lpMinted)
    {
        if (amountA == 0 || amountB == 0) revert ZeroAmount();

        uint256 supply = totalSupply();

        if (supply == 0) {
            // ── CASE 1: First deposit — set the initial price ─────────────────
            //
            // LP = sqrt(amountA × amountB) − MINIMUM_LIQUIDITY
            //
            // The geometric mean ensures DAY-1 depositors who set an unusual
            // ratio (e.g. 1 WATERS = 1000 USDC) still get a fair LP count.

            uint256 geomMean = _sqrt(amountA * amountB);
            if (geomMean <= MINIMUM_LIQUIDITY) revert InsufficientLiquidity();

            lpMinted = geomMean - MINIMUM_LIQUIDITY;

            // Permanently lock MINIMUM_LIQUIDITY — sent to the zero address.
            _mint(address(0), MINIMUM_LIQUIDITY);

        } else {
            // ── CASE 2: Subsequent deposit — preserve ratio ───────────────────
            //
            // LP minted is proportional to BOTH contributions.
            // We take the min so neither side is over-credited.
            //
            //   shareA = amountA / reserveA × totalSupply
            //   shareB = amountB / reserveB × totalSupply
            //   LP     = min(shareA, shareB)

            uint256 shareA = (amountA * supply) / reserveA;
            uint256 shareB = (amountB * supply) / reserveB;
            lpMinted = _min(shareA, shareB);
        }

        if (lpMinted == 0) revert ZeroLiquidity();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        reserveA += amountA;
        reserveB += amountB;
        _mint(msg.sender, lpMinted);

        // ── INTERACTIONS (last — C-E-I) ───────────────────────────────────────
        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        emit LiquidityAdded(msg.sender, amountA, amountB, lpMinted);
    }

    // ─── Liquidity: Remove ────────────────────────────────────────────────────

    /// @notice Burn LP Tokens to reclaim your proportional share of both tokens.
    ///
    /// @dev    PRO-RATA WITHDRAWAL:
    ///           amountA = lpAmount / totalSupply × reserveA
    ///           amountB = lpAmount / totalSupply × reserveB
    ///
    ///         Because LPs earn fees over time (k grows), the amount received
    ///         will be slightly more than what was originally deposited.
    ///         The difference is the LP's share of all accumulated swap fees.
    ///
    /// @param lpAmount     LP Tokens to burn.
    /// @return amountA     tokenA returned to caller.
    /// @return amountB     tokenB returned to caller.
    function removeLiquidity(uint256 lpAmount)
        external
        nonReentrant
        returns (uint256 amountA, uint256 amountB)
    {
        if (lpAmount == 0) revert ZeroAmount();

        uint256 supply = totalSupply();

        // Pro-rata shares of each reserve.
        amountA = (lpAmount * reserveA) / supply;
        amountB = (lpAmount * reserveB) / supply;

        if (amountA == 0 || amountB == 0) revert ZeroLiquidity();
        if (amountA > reserveA) revert InsufficientABalance();
        if (amountB > reserveB) revert InsufficientBBalance();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        reserveA -= amountA;
        reserveB -= amountB;
        _burn(msg.sender, lpAmount);

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    // ─── Swap: A → B ─────────────────────────────────────────────────────────

    /// @notice Sell tokenA, receive tokenB.  Uses x · y = k with 0.3% fee.
    ///
    /// @dev    STEP-BY-STEP DERIVATION OF THE SWAP FORMULA
    ///
    ///         Without fee:
    ///           x · y = k
    ///           (x + ΔA) · (y − ΔB) = k
    ///           ΔB = y − k / (x + ΔA)
    ///              = y · ΔA / (x + ΔA)    ← rearranged
    ///
    ///         With 0.3 % fee applied to the input:
    ///           effectiveIn = ΔA × 997 / 1000   (the fee stays in the pool)
    ///
    ///         Substituting effectiveIn for ΔA (integer-safe single expression):
    ///           amountOut = (ΔA × 997 × reserveB)
    ///                       / (reserveA × 1000 + ΔA × 997)
    ///
    ///         The 0.3 % that is NOT used in the formula stays in reserveA,
    ///         growing k.  This is how LPs are paid.
    ///
    ///         INVARIANT CHECK (post-swap safety):
    ///           newReserveA × newReserveB ≥ oldReserveA × oldReserveB
    ///           (Uses actual balances, not computed reserves, to catch
    ///            any tokens accidentally sent directly to the contract.)
    ///
    /// @param amountAIn    Exact tokenA to sell (must be pre-approved).
    /// @param minBOut      Minimum tokenB to accept (slippage protection).
    /// @return amountBOut  tokenB received.
    function swapAforB(uint256 amountAIn, uint256 minBOut)
        external
        nonReentrant
        returns (uint256 amountBOut)
    {
        if (amountAIn == 0) revert ZeroAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();

        // ── CONSTANT-PRODUCT FORMULA WITH 0.3% FEE ───────────────────────────
        //
        //   amountOut = (amountIn × 997 × reserveOut)
        //               / (reserveIn × 1000 + amountIn × 997)
        //
        uint256 amountInWithFee = amountAIn * FEE_NUMERATOR;          // ΔA × 997
        uint256 numerator       = amountInWithFee * reserveB;         // ΔA×997 × y
        uint256 denominator     = (reserveA * FEE_DENOMINATOR)        // x × 1000
                                  + amountInWithFee;                   // + ΔA×997
        amountBOut              = numerator / denominator;

        if (amountBOut == 0)          revert InsufficientOutputAmount();
        if (amountBOut < minBOut)     revert InsufficientOutputAmount(); // slippage
        if (amountBOut >= reserveB)   revert InsufficientLiquidity();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        reserveA += amountAIn;
        reserveB -= amountBOut;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        tokenA.safeTransferFrom(msg.sender, address(this), amountAIn);
        tokenB.safeTransfer(msg.sender, amountBOut);

        // ── POST-SWAP INVARIANT CHECK  x · y ≥ k ─────────────────────────────
        //   newReserveA × newReserveB must be ≥ old product.
        //   (Fees cause k to grow slightly, so this holds after valid swaps.)
        uint256 newProduct = reserveA * reserveB;
        uint256 oldProduct = (reserveA - amountAIn) * (reserveB + amountBOut);
        if (newProduct < oldProduct) revert InvariantViolated();

        emit SwapAforB(msg.sender, amountAIn, amountBOut);
    }

    // ─── Swap: B → A ─────────────────────────────────────────────────────────

    /// @notice Sell tokenB, receive tokenA.  Mirror of swapAforB.
    ///
    /// @dev    Same formula — just tokenA and tokenB roles are swapped:
    ///           amountOut = (ΔB × 997 × reserveA)
    ///                       / (reserveB × 1000 + ΔB × 997)
    ///
    /// @param amountBIn    Exact tokenB to sell (must be pre-approved).
    /// @param minAOut      Minimum tokenA to accept (slippage protection).
    /// @return amountAOut  tokenA received.
    function swapBforA(uint256 amountBIn, uint256 minAOut)
        external
        nonReentrant
        returns (uint256 amountAOut)
    {
        if (amountBIn == 0) revert ZeroAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();

        // ── CONSTANT-PRODUCT FORMULA WITH 0.3% FEE (B→A direction) ───────────
        uint256 amountInWithFee = amountBIn * FEE_NUMERATOR;          // ΔB × 997
        uint256 numerator       = amountInWithFee * reserveA;         // ΔB×997 × x
        uint256 denominator     = (reserveB * FEE_DENOMINATOR)        // y × 1000
                                  + amountInWithFee;                   // + ΔB×997
        amountAOut              = numerator / denominator;

        if (amountAOut == 0)          revert InsufficientOutputAmount();
        if (amountAOut < minAOut)     revert InsufficientOutputAmount(); // slippage
        if (amountAOut >= reserveA)   revert InsufficientLiquidity();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        reserveB += amountBIn;
        reserveA -= amountAOut;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        tokenB.safeTransferFrom(msg.sender, address(this), amountBIn);
        tokenA.safeTransfer(msg.sender, amountAOut);

        // ── POST-SWAP INVARIANT CHECK  x · y ≥ k ─────────────────────────────
        uint256 newProduct = reserveA * reserveB;
        uint256 oldProduct = (reserveA + amountAOut) * (reserveB - amountBIn);
        if (newProduct < oldProduct) revert InvariantViolated();

        emit SwapBforA(msg.sender, amountBIn, amountAOut);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Returns current pool reserves.
    function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB) {
        _reserveA = reserveA;
        _reserveB = reserveB;
    }

    /// @notice Preview how many B tokens you would receive for a given A input.
    ///         Off-chain UI helper — does not change state.
    ///
    /// @param amountAIn  tokenA you intend to sell.
    /// @return amountBOut  tokenB you would receive (after 0.3% fee).
    function getAmountOut_AtoB(uint256 amountAIn)
        external
        view
        returns (uint256 amountBOut)
    {
        if (amountAIn == 0 || reserveA == 0 || reserveB == 0) return 0;
        uint256 amountInWithFee = amountAIn * FEE_NUMERATOR;
        uint256 numerator       = amountInWithFee * reserveB;
        uint256 denominator     = (reserveA * FEE_DENOMINATOR) + amountInWithFee;
        amountBOut              = numerator / denominator;
    }

    /// @notice Preview how many A tokens you would receive for a given B input.
    ///
    /// @param amountBIn  tokenB you intend to sell.
    /// @return amountAOut  tokenA you would receive (after 0.3% fee).
    function getAmountOut_BtoA(uint256 amountBIn)
        external
        view
        returns (uint256 amountAOut)
    {
        if (amountBIn == 0 || reserveA == 0 || reserveB == 0) return 0;
        uint256 amountInWithFee = amountBIn * FEE_NUMERATOR;
        uint256 numerator       = amountInWithFee * reserveA;
        uint256 denominator     = (reserveB * FEE_DENOMINATOR) + amountInWithFee;
        amountAOut              = numerator / denominator;
    }

    /// @notice Returns the current implied price of tokenA in terms of tokenB.
    ///
    /// @dev    Spot price = reserveB / reserveA (scaled by 1e18 for decimals).
    ///         This is the "marginal price" — the price of an infinitely
    ///         small trade.  Actual trades experience slippage beyond this.
    ///
    /// @return price  tokenB per 1 tokenA (scaled × 1e18).
    function getSpotPrice() external view returns (uint256 price) {
        if (reserveA == 0) return 0;
        price = (reserveB * 1e18) / reserveA;
    }

    /// @notice Returns a full snapshot of the pool state.
    function getPoolInfo()
        external
        view
        returns (
            uint256 _reserveA,
            uint256 _reserveB,
            uint256 _totalLPSupply,
            uint256 _k,
            uint256 _spotPrice
        )
    {
        _reserveA      = reserveA;
        _reserveB      = reserveB;
        _totalLPSupply = totalSupply();
        _k             = reserveA * reserveB;
        _spotPrice     = reserveA == 0 ? 0 : (reserveB * 1e18) / reserveA;
    }

    // ─── Internal Math Helpers ────────────────────────────────────────────────

    /// @dev    Babylonian square-root — O(log n) Newton-Raphson iterations.
    ///
    ///         WHY THIS WORKS:
    ///         Newton's method for sqrt: x_{n+1} = (x_n + S/x_n) / 2
    ///         Starting from y/2 + 1 ensures convergence from above.
    ///         Loop terminates when the estimate stops improving (x >= z).
    ///
    ///         OVERFLOW SAFETY:
    ///         The largest possible input is type(uint256).max.
    ///         y/2 + 1 fits in uint256 since y <= type(uint256).max.
    ///         Intermediate y/x also fits since x >= 1.
    ///
    /// @param y  Value to take the square root of.
    /// @return z  Floor of sqrt(y).
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
        // y == 0 → z defaults to 0 (uint256 zero-value)
    }

    /// @dev Returns the smaller of two values.
    ///
    ///      Used in addLiquidity (Case 2) to take the binding constraint
    ///      between the A-contribution ratio and the B-contribution ratio.
    ///      Without `min`, a depositor could over-claim LP tokens relative
    ///      to their smaller contribution.
    ///
    /// @param a  First value.
    /// @param b  Second value.
    /// @return   The smaller of a and b.
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
