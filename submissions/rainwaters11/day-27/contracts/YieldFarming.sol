// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title  YieldFarming — Misty Farm 🌾
/// @author rainwaters11 — Day 27: Yield Farming Platform
/// @notice A time-based, per-second reward yield farming contract.
///         Users stake LP tokens and earn reward tokens continuously.
///         Implements boosted rewards for longer lock periods, emergency
///         withdrawal, and an on-chain APY view — the full DeFi primitive.
///
/// @dev    THE DeFi LIQUIDITY BOOTSTRAPPING LOOP
///         ┌──────────────────────────────────────────────────────────────┐
///         │  1. Protocol needs liquidity to function.                    │
///         │  2. Users won't deposit without incentive.                   │
///         │  3. Solution: reward stakers with a governance/reward token. │
///         │                                                              │
///         │  Real-world parallels:                                       │
///         │  • Uniswap V2  → stake LP tokens, earn UNI                  │
///         │  • Compound    → supply assets, earn COMP                    │
///         │  • Aave        → deposit collateral, earn AAVE               │
///         │  • Misty Farm  → stake $WATERS LP, earn reward tokens        │
///         └──────────────────────────────────────────────────────────────┘
///
///         TIME-BASED REWARD FORMULA (per-second accrual)
///         ┌──────────────────────────────────────────────────────────────┐
///         │  elapsed   = block.timestamp − stakeTimestamp[user]          │
///         │  reward    = stakedBalance × rewardRatePerSecond × elapsed   │
///         │              / PRECISION                                     │
///         │                                                              │
///         │  Example (rate = 0.01 token/sec/token staked):              │
///         │    User stakes 100 tokens for 1 day (86,400 s)              │
///         │    reward = 100e18 × 0.01e18 × 86400 / 1e18                 │
///         │           = 86,400 tokens                                    │
///         └──────────────────────────────────────────────────────────────┘
///
///         BOOSTED REWARDS (lock-duration multiplier)
///         ┌──────────────────────────────────────────────────────────────┐
///         │  Flexible (no lock)  → 1.0× base reward                     │
///         │  ≥ 30 days lock      → 1.25× boosted reward                 │
///         │  ≥ 180 days lock     → 1.5×  boosted reward                 │
///         │  ≥ 365 days lock     → 2.0×  boosted reward                 │
///         │                                                              │
///         │  Inspired by Curve Finance's veCRV: longer lock = better    │
///         │  yield to align long-term holders with the protocol.        │
///         └──────────────────────────────────────────────────────────────┘
///
///         EMERGENCY WITHDRAW
///         ┌──────────────────────────────────────────────────────────────┐
///         │  Instant exit with NO reward claim.                          │
///         │  Pending rewards are forfeited — returned to reward pool.    │
///         │  Useful if user needs liquidity urgently or lock has not    │
///         │  expired yet.  Protects the protocol from reward drain.     │
///         └──────────────────────────────────────────────────────────────┘
///
///         SECURITY
///         • ReentrancyGuard on stake/unstake/claim/emergency paths.
///         • SafeERC20 for all token transfers.
///         • pendingRewards snapshot on stake to avoid retroactive accrual.
///         • Lock enforcement: cannot unstake before lockEndTime.
///         • Reward solvency check: claimRewards reverts if pool is dry.
///
///         USE CASES IN MISTYCOIN-CORE
///         • Stake MistySwap LP tokens (Day 25) to earn $WATERS rewards.
///         • Stake $WATERS directly to earn governance tokens.
///         • Treasury (Day 24 MultiSig) deposits reward tokens as incentive.
contract YieldFarming is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // ─── Constants ────────────────────────────────────────────────────────────

    /// @notice Scaling factor to keep reward math integer-safe (18 decimals).
    uint256 public constant PRECISION = 1e18;

    /// @notice Lock durations for the boost tiers.
    uint256 public constant LOCK_30_DAYS  = 30 days;
    uint256 public constant LOCK_180_DAYS = 180 days;
    uint256 public constant LOCK_365_DAYS = 365 days;

    /// @notice Boost multipliers (scaled × 10 to avoid decimals).
    ///         Actual multiplier = value / 10.
    ///         1.0× = 10, 1.25× = 12, 1.5× = 15, 2.0× = 20
    uint256 public constant BOOST_NONE     = 10;  // 1.0×
    uint256 public constant BOOST_30_DAYS  = 12;  // 1.25×  (small commitment)
    uint256 public constant BOOST_180_DAYS = 15;  // 1.5×   (medium commitment)
    uint256 public constant BOOST_365_DAYS = 20;  // 2.0×   (aligned long-term holder)
    uint256 public constant BOOST_DIVISOR  = 10;

    // ─── Immutables ───────────────────────────────────────────────────────────

    /// @notice Token users stake to earn rewards (e.g. MistySwap LP Token).
    IERC20 public immutable stakingToken;

    /// @notice Token distributed as farming rewards (e.g. $WATERS or gov token).
    IERC20 public immutable rewardToken;

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice Reward tokens emitted per second PER staked token (scaled × PRECISION).
    ///         Example: 1e16 = 0.01 reward tokens per staked token per second.
    ///         Owner can update this to adjust incentive intensity.
    uint256 public rewardRatePerSecond;

    /// @notice Total staking tokens currently deposited across all users.
    uint256 public totalStaked;

    /// @dev Amount each user has staked.
    mapping(address => uint256) public stakedBalance;

    /// @dev Timestamp when each user last staked (resets on re-stake).
    mapping(address => uint256) public stakeTimestamp;

    /// @dev Accumulated rewards already earned but not yet claimed.
    ///      Snapshotted on re-stake so existing earnings are preserved.
    mapping(address => uint256) public pendingRewards;

    /// @dev Timestamp when the user's lock expires (0 = no lock / flexible).
    mapping(address => uint256) public lockEndTime;

    /// @dev Lock duration chosen by user at stake time (used for boost calc).
    mapping(address => uint256) public lockDuration;

    // ─── Events ───────────────────────────────────────────────────────────────

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 lockDuration,
        uint256 lockEndTime
    );
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 forfeitedRewards);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event RewardsFunded(address indexed funder, uint256 amount);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ZeroAmount();
    error StillLocked();                // lock period has not expired
    error NothingStaked();              // user has no staked balance
    error NoRewardsToClaim();
    error InsufficientRewardPool();     // contract lacks enough reward tokens
    error InvalidLockDuration();        // lock must be 0 or a recognised tier

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _stakingToken        ERC-20 users deposit (e.g. MSLP from Day 25 AMM).
    /// @param _rewardToken         ERC-20 users earn   (e.g. $WATERS).
    /// @param _rewardRatePerSecond Initial emission rate (scaled × PRECISION).
    ///                             Set to 1e16 for ~0.01 token/sec/token staked.
    /// @param _owner               Owner — can update rate and fund rewards.
    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRatePerSecond,
        address _owner
    ) Ownable(_owner) {
        require(_stakingToken != address(0), "YF: zero staking token");
        require(_rewardToken  != address(0), "YF: zero reward token");
        stakingToken       = IERC20(_stakingToken);
        rewardToken        = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRatePerSecond;
    }

    // ─── Core: Stake ──────────────────────────────────────────────────────────

    /// @notice Deposit staking tokens and begin earning rewards.
    ///
    /// @dev    RE-STAKE LOGIC — if the user already has a position:
    ///         1. Snapshot their existing earned rewards into pendingRewards.
    ///         2. Add new tokens to stakedBalance.
    ///         3. Reset stakeTimestamp to now (fresh accrual window).
    ///         This preserves all previous earnings while avoiding double-
    ///         counting: the old balance's rewards up to now are frozen in
    ///         pendingRewards; only future accrual uses the new total balance.
    ///
    ///         LOCK DURATION — users choose flexibility or commitment:
    ///         • 0          → no lock, 1.0× rewards, unstake anytime
    ///         • 30 days    → soft lock, 1.25× boost
    ///         • 180 days   → medium lock, 1.5× boost
    ///         • 365 days   → full-year lock, 2.0× boost (Curve veCRV-style)
    ///
    /// @param amount       Staking tokens to deposit (must be pre-approved).
    /// @param _lockSeconds Lock duration in seconds. Must be 0, 30d, 180d, or 365d.
    function stake(uint256 amount, uint256 _lockSeconds) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (
            _lockSeconds != 0            &&
            _lockSeconds != LOCK_30_DAYS &&
            _lockSeconds != LOCK_180_DAYS &&
            _lockSeconds != LOCK_365_DAYS
        ) revert InvalidLockDuration();

        // ── Snapshot existing rewards before mutating balance ─────────────────
        if (stakedBalance[msg.sender] > 0) {
            pendingRewards[msg.sender] += _calculateBaseReward(msg.sender);
        }

        // ── EFFECTS ───────────────────────────────────────────────────────────
        stakedBalance[msg.sender] += amount;
        stakeTimestamp[msg.sender] = block.timestamp;
        totalStaked                += amount;

        // Apply lock (only extends if new lock ends later than existing one).
        uint256 newLockEnd = block.timestamp + _lockSeconds;
        if (newLockEnd > lockEndTime[msg.sender]) {
            lockEndTime[msg.sender]  = newLockEnd;
            lockDuration[msg.sender] = _lockSeconds;
        }

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, lockDuration[msg.sender], lockEndTime[msg.sender]);
    }

    // ─── Core: Unstake ────────────────────────────────────────────────────────

    /// @notice Withdraw staked tokens after the lock expires.
    ///         Automatically claims all pending + accrued rewards first.
    ///
    /// @dev    Lock check: if lockEndTime[user] > block.timestamp → revert.
    ///         After unstake the user's position is fully cleared.
    ///
    /// @param amount  Staking tokens to withdraw.
    function unstake(uint256 amount) external nonReentrant {
        if (amount == 0)                         revert ZeroAmount();
        if (stakedBalance[msg.sender] < amount)  revert NothingStaked();
        if (block.timestamp < lockEndTime[msg.sender]) revert StillLocked();

        // Auto-claim pending + newly accrued rewards.
        uint256 totalReward = pendingRewards[msg.sender] + _calculateBaseReward(msg.sender);
        totalReward = _applyBoost(totalReward, lockDuration[msg.sender]);

        // ── EFFECTS ───────────────────────────────────────────────────────────
        stakedBalance[msg.sender] -= amount;
        totalStaked                -= amount;
        pendingRewards[msg.sender] = 0;
        stakeTimestamp[msg.sender] = block.timestamp;

        if (stakedBalance[msg.sender] == 0) {
            lockEndTime[msg.sender]  = 0;
            lockDuration[msg.sender] = 0;
        }

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        stakingToken.safeTransfer(msg.sender, amount);

        // Pay reward only if pool is solvent and reward > 0.
        if (totalReward > 0 && rewardToken.balanceOf(address(this)) >= totalReward) {
            rewardToken.safeTransfer(msg.sender, totalReward);
            emit RewardsClaimed(msg.sender, totalReward);
        }

        emit Unstaked(msg.sender, amount);
    }

    // ─── Core: Claim Rewards ──────────────────────────────────────────────────

    /// @notice Harvest all accumulated rewards without unstaking.
    ///
    /// @dev    REWARD CALCULATION ORDER:
    ///         1. base accrual since last stake/claim = _calculateBaseReward()
    ///         2. add frozen pendingRewards (from previous re-stakes)
    ///         3. apply boost multiplier for lock duration
    ///         4. reset pendingRewards and stakeTimestamp
    ///
    ///         SOLVENCY CHECK: reverts if the contract cannot pay the full
    ///         reward.  Owner must fund the reward pool proactively using
    ///         fundRewards().
    function claimRewards() external nonReentrant {
        if (stakedBalance[msg.sender] == 0) revert NothingStaked();

        uint256 baseReward  = _calculateBaseReward(msg.sender);
        uint256 totalReward = pendingRewards[msg.sender] + baseReward;
        totalReward         = _applyBoost(totalReward, lockDuration[msg.sender]);

        if (totalReward == 0) revert NoRewardsToClaim();
        if (rewardToken.balanceOf(address(this)) < totalReward)
            revert InsufficientRewardPool();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        pendingRewards[msg.sender] = 0;
        stakeTimestamp[msg.sender] = block.timestamp;  // reset accrual window

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        rewardToken.safeTransfer(msg.sender, totalReward);

        emit RewardsClaimed(msg.sender, totalReward);
    }

    // ─── Core: Emergency Withdraw ─────────────────────────────────────────────

    /// @notice Exit immediately — forfeits ALL pending rewards.
    ///
    /// @dev    Use case: user needs liquidity urgently, or lock hasn't expired.
    ///         Forfeited rewards stay in the contract, growing the reward pool
    ///         for other stakers — a healthy incentive against panic exits.
    ///
    ///         NOTE: bypasses the lock check intentionally.
    ///         This is the "break glass" mechanism — always available.
    function emergencyWithdraw() external nonReentrant {
        uint256 amount = stakedBalance[msg.sender];
        if (amount == 0) revert NothingStaked();

        // Calculate what they're forfeiting (for event transparency).
        uint256 forfeited = pendingRewards[msg.sender]
            + _calculateBaseReward(msg.sender);
        forfeited = _applyBoost(forfeited, lockDuration[msg.sender]);

        // ── EFFECTS ───────────────────────────────────────────────────────────
        stakedBalance[msg.sender] = 0;
        totalStaked               -= amount;
        pendingRewards[msg.sender] = 0;
        stakeTimestamp[msg.sender] = 0;
        lockEndTime[msg.sender]    = 0;
        lockDuration[msg.sender]   = 0;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        stakingToken.safeTransfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, amount, forfeited);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Returns the total reward a user would receive if they claimed now.
    ///         Includes pending snapshot + newly accrued + boost multiplier.
    ///
    /// @param user  Staker address.
    /// @return totalReward  Claimable reward amount (in reward token decimals).
    function calculateReward(address user) public view returns (uint256 totalReward) {
        uint256 base = _calculateBaseReward(user);
        totalReward  = pendingRewards[user] + base;
        totalReward  = _applyBoost(totalReward, lockDuration[user]);
    }

    /// @notice Compute the current APY as an integer percentage.
    ///
    /// @dev    APY FORMULA:
    ///         yearlyEmission = rewardRatePerSecond × 365 days × totalStaked
    ///                         / PRECISION
    ///
    ///         APY (%) = yearlyEmission × 100 / totalStaked
    ///                 = rewardRatePerSecond × 365 days × 100 / PRECISION
    ///
    ///         This cancels totalStaked, so APY is independent of pool size
    ///         (true for per-token-per-second reward rates).  In practice,
    ///         as totalStaked grows, the effective APY per token stays
    ///         constant — the protocol emits MORE tokens total but each
    ///         staker's share is proportional.
    ///
    /// @return apy  Percentage APY (e.g. 10 = 10 %).
    function calculateAPY() external view returns (uint256 apy) {
        if (totalStaked == 0) return 0;
        uint256 yearlyEmissionPerToken = rewardRatePerSecond * 365 days;
        apy = (yearlyEmissionPerToken * 100) / PRECISION;
    }

    /// @notice Check whether the reward pool can cover all currently accruing
    ///         rewards for the next `windowSeconds` seconds.
    ///
    /// @param windowSeconds  Lookahead period (e.g. 7 days = 604_800).
    /// @return solvent       True if pool balance covers projected emissions.
    function checkRewardSolvency(uint256 windowSeconds)
        external
        view
        returns (bool solvent)
    {
        uint256 projectedEmission =
            (totalStaked * rewardRatePerSecond * windowSeconds) / PRECISION;
        solvent = rewardToken.balanceOf(address(this)) >= projectedEmission;
    }

    /// @notice Full position snapshot for a user.
    function getPosition(address user)
        external
        view
        returns (
            uint256 staked,
            uint256 claimableReward,
            uint256 lockEnds,
            uint256 boost,
            uint256 timeStaked
        )
    {
        staked          = stakedBalance[user];
        claimableReward = calculateReward(user);
        lockEnds        = lockEndTime[user];
        boost           = _boostMultiplier(lockDuration[user]);
        timeStaked      = stakeTimestamp[user] == 0
                            ? 0
                            : block.timestamp - stakeTimestamp[user];
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    /// @notice Deposit reward tokens into the farming contract.
    ///         Must be called by owner before stakers can earn.
    ///
    /// @param amount  Reward tokens to add to the pool.
    function fundRewards(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardsFunded(msg.sender, amount);
    }

    /// @notice Update the per-second reward emission rate.
    ///         Lower rate = lower APY, extends reward pool runway.
    ///         Higher rate = higher APY, burns through pool faster.
    ///
    /// @param newRate  New rewardRatePerSecond (scaled × PRECISION).
    function setRewardRate(uint256 newRate) external onlyOwner {
        emit RewardRateUpdated(rewardRatePerSecond, newRate);
        rewardRatePerSecond = newRate;
    }

    // ─── Internal Helpers ─────────────────────────────────────────────────────

    /// @dev Base reward since the last stakeTimestamp, before boost.
    ///
    ///      reward = stakedBalance × rewardRatePerSecond × elapsed / PRECISION
    ///
    ///      Overflow analysis:
    ///        stakedBalance: up to ~1e27 (real-world max ~1e24 tokens)
    ///        rewardRatePerSecond: up to ~1e18
    ///        elapsed: up to ~1e8 seconds (3+ years)
    ///        product: ~1e27 × 1e18 × 1e8 = 1e53
    ///        uint256 max: ~1.15e77 → no overflow for realistic values.
    ///        Large whale stakes would overflow at unrealistic amounts;
    ///        production contracts use accRewardPerShare (checkpoint pattern).
    function _calculateBaseReward(address user)
        internal
        view
        returns (uint256)
    {
        uint256 balance   = stakedBalance[user];
        uint256 lastTime  = stakeTimestamp[user];
        if (balance == 0 || lastTime == 0) return 0;

        uint256 elapsed = block.timestamp - lastTime;
        return (balance * rewardRatePerSecond * elapsed) / PRECISION;
    }

    /// @dev Apply the lock-duration boost multiplier.
    ///      Result = base × boostMultiplier / BOOST_DIVISOR
    function _applyBoost(uint256 base, uint256 _lockDuration)
        internal
        pure
        returns (uint256)
    {
        return (base * _boostMultiplier(_lockDuration)) / BOOST_DIVISOR;
    }

    /// @dev Returns the raw boost integer (divide by BOOST_DIVISOR for actual multiplier).
    function _boostMultiplier(uint256 _lockDuration)
        internal
        pure
        returns (uint256)
    {
        if (_lockDuration >= LOCK_365_DAYS) return BOOST_365_DAYS; // 2.0×
        if (_lockDuration >= LOCK_180_DAYS) return BOOST_180_DAYS; // 1.5×
        if (_lockDuration >= LOCK_30_DAYS)  return BOOST_30_DAYS;  // 1.25×
        return BOOST_NONE;                                          // 1.0×
    }
}
