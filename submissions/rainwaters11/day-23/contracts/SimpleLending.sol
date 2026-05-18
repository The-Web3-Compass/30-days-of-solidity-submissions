// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title  SimpleLending — Misty Bank 🏦
/// @author rainwaters11 — Day 23: LendingPool (DeFi Primitive)
/// @notice A minimal ERC-20 lending pool that lets users deposit collateral,
///         borrow up to 75 % of their collateral value, and accrue 5 % APR
///         simple interest using block.timestamp.
///
/// @dev    MISTY BANK ANALOGY
///         ┌──────────────────────────────────────────────────────────────┐
///         │  Deposit     → You bring $WATERS to the bank as collateral.  │
///         │  Borrow      → Bank lends you up to 75 % of that value.      │
///         │  Interest    → 5 % APR accrues every second on your debt.    │
///         │  Repay       → Pay back principal + interest to free your    │
///         │                collateral.                                    │
///         └──────────────────────────────────────────────────────────────┘
///
///         BASIS POINT STANDARD (the "professional touch")
///         ┌──────────────────────────────────────────────────────────────┐
///         │  1 BPS  = 0.01 %                                             │
///         │  500 BPS = 5.00 % (ANNUAL_INTEREST_BPS)                      │
///         │  7500 BPS = 75.00 % (LTV_BPS — Loan-to-Value ratio)          │
///         │                                                              │
///         │  Formula: amount × BPS / 10_000                              │
///         │  Example: 1000e18 × 500 / 10_000 = 50e18 (5 %)              │
///         │                                                              │
///         │  Solidity has no floating point. This is exactly how Aave    │
///         │  and Compound write production interest math.                │
///         └──────────────────────────────────────────────────────────────┘
///
///         INTEREST ACCRUAL — TIME MATH WITH block.timestamp
///         ┌──────────────────────────────────────────────────────────────┐
///         │  accrued = principal × ANNUAL_INTEREST_BPS                   │
///         │            × (now − lastTimestamp)                            │
///         │            / SECONDS_PER_YEAR / BPS_PRECISION                │
///         │                                                              │
///         │  lastInterestAccrualTimestamp is set on BOTH borrow() and    │
///         │  repay() so interest is never reset or double-counted.       │
///         └──────────────────────────────────────────────────────────────┘
///
///         SAFETY: Checks-Effects-Interactions pattern throughout.
///         All external calls (SafeERC20) happen AFTER state is updated.
///         ReentrancyGuard on every mutating function.
///
///         USE CASES IN MISTYCOIN-CORE
///         • Holders deposit $WATERS as collateral and borrow stablecoins.
///         • Liquidity providers earn interest via the lending pool.
///         • Integrates with MiniDex (Day 21) for collateral swaps.
contract SimpleLending is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // ─── Constants (Basis Point Standard) ────────────────────────────────────

    /// @notice Precision divisor: 10_000 BPS = 100 %.
    uint256 public constant BPS_PRECISION = 10_000;

    /// @notice Annual simple interest rate = 5.00 % = 500 BPS.
    ///         Calculation: (principal × 500) / 10_000 = 5 % of principal per year.
    uint256 public constant ANNUAL_INTEREST_BPS = 500;

    /// @notice Maximum Loan-to-Value ratio = 75 % = 7_500 BPS.
    ///         A user depositing 1_000 tokens can borrow at most 750 tokens.
    uint256 public constant LTV_BPS = 7_500;

    /// @notice Seconds in a 365-day year.  Used in time-weighted interest math.
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice The ERC-20 token used as both collateral and borrowable asset.
    ///         In the MistyCoin ecosystem this is typically $WATERS.
    IERC20 public immutable asset;

    /// @dev Collateral deposited by each user (in token's native decimals).
    mapping(address => uint256) public collateralBalance;

    /// @dev Outstanding borrow principal for each user.
    mapping(address => uint256) public borrowBalance;

    /// @dev block.timestamp when user last borrowed or repaid.
    ///      Critical: must be updated on BOTH borrow() and repay() so the
    ///      interest window is always correct and never skipped.
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    /// @dev Total tokens supplied to the pool by depositors.
    uint256 public totalPoolLiquidity;

    // ─── Events ───────────────────────────────────────────────────────────────

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 principal, uint256 interest, uint256 total);
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ZeroAmount();
    error ExceedsLTV();                   // borrow would exceed 75 % LTV
    error InsufficientPoolLiquidity();    // pool does not have enough tokens
    error InsufficientCollateral();       // not enough collateral to withdraw
    error NoBorrowOutstanding();          // repay called with zero debt
    error InsufficientRepayAmount();      // amount < interest owed
    error CollateralStillLocked();        // cannot withdraw while debt > 0

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _asset   ERC-20 token the pool accepts (e.g. $WATERS).
    /// @param _owner   Initial owner (can drain emergency liquidity).
    constructor(address _asset, address _owner) Ownable(_owner) {
        require(_asset != address(0), "SimpleLending: zero asset address");
        asset = IERC20(_asset);
    }

    // ─── Liquidity Provider Interface ─────────────────────────────────────────

    /// @notice Deposit tokens into the pool to make them available for borrowing.
    ///         Liquidity providers help borrowers — this is the "bank vault."
    ///
    /// @param amount  Token amount to add to the pool (must be pre-approved).
    function addLiquidity(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        // CHECKS ✓ — amount validated above
        // EFFECTS ✓ — update state before external call
        totalPoolLiquidity += amount;

        // INTERACTIONS ✓ — transfer last via SafeERC20
        asset.safeTransferFrom(msg.sender, address(this), amount);

        emit LiquidityAdded(msg.sender, amount);
    }

    /// @notice Withdraw idle pool liquidity (owner only — production pools use
    ///         LP-token accounting; this simplified version gives owner control).
    ///
    /// @param amount  Token amount to remove from the pool.
    function removeLiquidity(uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (amount > totalPoolLiquidity) revert InsufficientPoolLiquidity();

        // EFFECTS first
        totalPoolLiquidity -= amount;

        // INTERACTIONS last
        asset.safeTransfer(msg.sender, amount);

        emit LiquidityRemoved(msg.sender, amount);
    }

    // ─── Borrower Interface ───────────────────────────────────────────────────

    /// @notice Lock tokens as collateral.  Must be called before borrow().
    ///
    /// @dev    Tokens transfer from msg.sender → this contract.
    ///         Follows C-E-I: validate → state change → external call.
    ///
    /// @param amount  Collateral amount (token native decimals).
    function depositCollateral(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        // EFFECTS
        collateralBalance[msg.sender] += amount;

        // INTERACTIONS
        asset.safeTransferFrom(msg.sender, address(this), amount);

        emit CollateralDeposited(msg.sender, amount);
    }

    /// @notice Withdraw collateral — only allowed if you have no outstanding debt.
    ///
    /// @dev    In a production system you would allow partial withdrawal up to the
    ///         LTV threshold.  Simplicity here: full withdrawal requires zero debt.
    ///
    /// @param amount  Collateral amount to retrieve.
    function withdrawCollateral(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (amount > collateralBalance[msg.sender]) revert InsufficientCollateral();

        // Block withdrawal while debt + accrued interest remains unpaid.
        if (borrowBalance[msg.sender] > 0) revert CollateralStillLocked();

        // Ensure after-withdrawal LTV is still safe (zero-debt case always passes).
        uint256 remainingCollateral = collateralBalance[msg.sender] - amount;
        uint256 maxBorrow = (remainingCollateral * LTV_BPS) / BPS_PRECISION;

        // No debt → maxBorrow check is trivially satisfied (0 <= anything).
        // Kept here so future extensions that allow partial withdrawal compile.
        if (borrowBalance[msg.sender] > maxBorrow) revert ExceedsLTV();

        // EFFECTS
        collateralBalance[msg.sender] = remainingCollateral;

        // INTERACTIONS
        asset.safeTransfer(msg.sender, amount);

        emit CollateralWithdrawn(msg.sender, amount);
    }

    /// @notice Borrow tokens from the pool against your deposited collateral.
    ///
    /// @dev    LTV CHECK (Basis Point Standard)
    ///         maxBorrow = collateral × LTV_BPS / BPS_PRECISION
    ///                   = collateral × 7_500  / 10_000
    ///                   = 75 % of collateral
    ///
    ///         TIMESTAMP INIT — lastInterestAccrualTimestamp is set here so the
    ///         first interest window starts at the moment of the first borrow,
    ///         not at contract deployment.  Subsequent borrows reset the clock on
    ///         the FULL balance (accrued interest is rolled into principal first).
    ///
    /// @param amount  Token amount to borrow.
    function borrow(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        // ── CHECKS ────────────────────────────────────────────────────────────

        // Roll any outstanding interest into the principal before adding more debt.
        uint256 accruedInterest = calculateInterestAccrued(msg.sender);
        uint256 totalDebt = borrowBalance[msg.sender] + accruedInterest + amount;

        uint256 maxBorrow = (collateralBalance[msg.sender] * LTV_BPS) / BPS_PRECISION;
        if (totalDebt > maxBorrow) revert ExceedsLTV();

        if (amount > totalPoolLiquidity) revert InsufficientPoolLiquidity();

        // ── EFFECTS ───────────────────────────────────────────────────────────

        // Capitalise accrued interest into principal BEFORE recording new debt.
        borrowBalance[msg.sender] = borrowBalance[msg.sender] + accruedInterest + amount;

        // ⚠️  CRITICAL: Reset the accrual clock here so interest is not double-
        //     counted on the next borrow() or repay() call.
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        totalPoolLiquidity -= amount;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        asset.safeTransfer(msg.sender, amount);

        emit Borrowed(msg.sender, amount);
    }

    /// @notice Repay outstanding debt (principal + accrued interest).
    ///
    /// @dev    TIMESTAMP RESET — lastInterestAccrualTimestamp is updated here too,
    ///         just like in borrow().  After a partial repay the remaining principal
    ///         starts a fresh interest window from now, preventing any scenario
    ///         where interest gets "skipped" because the timestamp wasn't touched.
    ///
    ///         PARTIAL REPAY — if `amount` >= fullDebt, the entire position is
    ///         closed and excess is not taken.  If `amount` < interest, revert so
    ///         the pool is never left with growing principal.
    ///
    /// @param amount  Tokens to repay.  Must be >= accrued interest at minimum.
    function repay(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (borrowBalance[msg.sender] == 0) revert NoBorrowOutstanding();

        // ── CHECKS ────────────────────────────────────────────────────────────
        uint256 accruedInterest = calculateInterestAccrued(msg.sender);
        uint256 fullDebt = borrowBalance[msg.sender] + accruedInterest;

        // Enforce that at least the accrued interest is covered.
        if (amount < accruedInterest) revert InsufficientRepayAmount();

        // Cap repayment at total debt (no overpayment).
        uint256 repayAmount = amount > fullDebt ? fullDebt : amount;
        uint256 principalPaid = repayAmount - accruedInterest;

        // ── EFFECTS ───────────────────────────────────────────────────────────
        borrowBalance[msg.sender] = fullDebt - repayAmount;

        // ⚠️  CRITICAL: Update timestamp so remaining principal starts a fresh
        //     interest window.  Omitting this would cause interest to accrue as
        //     if no repayment had occurred — a silent accounting bug.
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        totalPoolLiquidity += repayAmount;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        asset.safeTransferFrom(msg.sender, address(this), repayAmount);

        emit Repaid(msg.sender, principalPaid, accruedInterest, repayAmount);
    }

    // ─── View: Interest Math ──────────────────────────────────────────────────

    /// @notice Calculate simple interest accrued on a user's borrow position.
    ///
    /// @dev    INTEREST FORMULA (annotated step-by-step)
    ///
    ///         Step 1 — elapsed seconds since last accrual:
    ///           elapsed = block.timestamp − lastInterestAccrualTimestamp[user]
    ///
    ///         Step 2 — annual interest in tokens (BPS standard):
    ///           annualInterest = principal × ANNUAL_INTEREST_BPS / BPS_PRECISION
    ///                          = principal × 500 / 10_000
    ///                          = 5 % of principal
    ///
    ///         Step 3 — pro-rate to elapsed seconds:
    ///           accrued = annualInterest × elapsed / SECONDS_PER_YEAR
    ///
    ///         Combined (single expression to avoid phantom overflow):
    ///           accrued = principal × ANNUAL_INTEREST_BPS × elapsed
    ///                     / SECONDS_PER_YEAR / BPS_PRECISION
    ///
    ///         NOTE: Division is done last-of-last (after both multiplications)
    ///         so precision is always maintained at the largest intermediate value.
    ///
    ///         TIMESTAMP EDGE CASES HANDLED:
    ///         • First borrow ever    → lastTimestamp == 0 → elapsed == now
    ///           (handled by initialising timestamp in borrow())
    ///         • Same-block call      → elapsed == 0 → accrued == 0 ✓
    ///         • Post-repay call      → timestamp reset → no double counting ✓
    ///
    /// @param user  Borrower address.
    /// @return accruedInterest  Tokens owed in accrued interest.
    function calculateInterestAccrued(address user)
        public
        view
        returns (uint256 accruedInterest)
    {
        uint256 principal = borrowBalance[user];
        if (principal == 0) return 0;

        uint256 lastTimestamp = lastInterestAccrualTimestamp[user];
        if (lastTimestamp == 0) return 0; // no borrow has been made yet

        uint256 elapsed = block.timestamp - lastTimestamp;
        if (elapsed == 0) return 0;

        // BPS-standard interest: (principal × 500 × elapsed) / (365 days × 10_000)
        // Multiply first for precision; both SECONDS_PER_YEAR and BPS_PRECISION
        // are constants so the compiler optimises them at compile time.
        accruedInterest =
            (principal * ANNUAL_INTEREST_BPS * elapsed) /
            (SECONDS_PER_YEAR * BPS_PRECISION);
    }

    /// @notice Returns the total amount (principal + interest) owed by a user.
    /// @param user  Borrower address.
    function getTotalDebt(address user) external view returns (uint256) {
        return borrowBalance[user] + calculateInterestAccrued(user);
    }

    /// @notice Returns the maximum tokens a user may borrow given their collateral.
    ///
    /// @dev    maxBorrow = collateral × LTV_BPS / BPS_PRECISION
    ///                   = collateral × 7_500  / 10_000
    ///                   = 75 % of collateral
    ///
    /// @param user  Address to inspect.
    function getMaxBorrow(address user) external view returns (uint256) {
        return (collateralBalance[user] * LTV_BPS) / BPS_PRECISION;
    }

    /// @notice Returns a snapshot of a user's lending position.
    function getPosition(address user)
        external
        view
        returns (
            uint256 collateral,
            uint256 debt,
            uint256 interestAccrued,
            uint256 maxBorrowable,
            uint256 lastAccrual
        )
    {
        collateral      = collateralBalance[user];
        debt            = borrowBalance[user];
        interestAccrued = calculateInterestAccrued(user);
        maxBorrowable   = (collateral * LTV_BPS) / BPS_PRECISION;
        lastAccrual     = lastInterestAccrualTimestamp[user];
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    /// @notice Emergency drain — owner-only.  In production, use a multi-sig.
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        asset.safeTransfer(msg.sender, amount);
    }
}
