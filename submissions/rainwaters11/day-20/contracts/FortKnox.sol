// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title  FortKnox
/// @author rainwaters11 — Day 27: Reentrancy Protection
/// @notice A hardened ETH vault demonstrating every layer of defence against
///         the #1 most costly bug in Solidity history: reentrancy.
///
/// @dev    ═══════════════════════════════════════════════════════════════
///         THE REENTRANCY ATTACK — what we are defending against
///         ═══════════════════════════════════════════════════════════════
///
///         A classic VULNERABLE withdraw looks like this:
///
///             function withdraw() external {
///                 uint256 amount = balances[msg.sender];
///                 require(amount > 0);
///                 (bool ok,) = msg.sender.call{value: amount}("");  // 1. send ETH
///                 require(ok);
///                 balances[msg.sender] = 0;                         // 2. zero balance
///             }
///
///         An attacker's contract has a receive() that calls withdraw() again
///         BEFORE step 2 runs.  Because the balance is still non-zero on re-
///         entry, the attacker can drain the vault in a loop.
///         This is exactly how $60M was stolen from The DAO in 2016.
///
///         ═══════════════════════════════════════════════════════════════
///         FORT KNOX — THREE LAYERS OF DEFENCE
///         ═══════════════════════════════════════════════════════════════
///
///         Layer 1 — Checks-Effects-Interactions (CEI) pattern
///                   The "Golden Rule" of Solidity:
///
///             CHECK   → require(balance >= amount)  verify the request
///             EFFECT  → balance = 0                 update books FIRST
///             INTERACT→ msg.sender.call(...)         talk to the outside last
///
///         Layer 2 — Mutex lock via ReentrancyGuard
///                   OpenZeppelin's nonReentrant modifier sets a flag on entry
///                   and clears it on exit.  Any re-entrant call hits the
///                   locked flag and reverts immediately — even if CEI is broken
///                   elsewhere in the code.
///
///         Layer 3 — Pull-over-push payments
///                   Users call withdraw() themselves (pull).  The contract
///                   never proactively pushes ETH to addresses, so there is
///                   no attack surface from the contract's side.
///
///         ═══════════════════════════════════════════════════════════════
///         CONNECTION TO MISTICOIN-CORE
///         ═══════════════════════════════════════════════════════════════
///         • Day 18 CropInsurance: payouts go through the same CEI pattern.
///         • Day 29 SimpleStablecoin: collateral withdrawals use nonReentrant.
///         • Day 30 MiniDexPair: all swap/liquidity functions inherit this guard.
contract FortKnox is ReentrancyGuard, Ownable {

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice Tracks each user's deposited ETH balance (in wei).
    mapping(address => uint256) public balances;

    /// @notice Total ETH currently held in the vault.
    uint256 public totalDeposits;

    // ─── Events ───────────────────────────────────────────────────────────────

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed owner, uint256 amount);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ZeroDeposit();
    error InsufficientBalance();
    error ETHTransferFailed();
    error ZeroBalance();

    // ─── Constructor ──────────────────────────────────────────────────────────

    constructor(address _owner) Ownable(_owner) {}

    // ─── Deposit ──────────────────────────────────────────────────────────────

    /// @notice Deposit ETH into the vault.
    /// @dev    Anyone can deposit; the sent value is credited to msg.sender.
    function deposit() external payable {
        if (msg.value == 0) revert ZeroDeposit();

        balances[msg.sender] += msg.value;
        totalDeposits         += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    // ─── Withdraw — every defence in one function ──────────────────────────────

    /// @notice Withdraw your full ETH balance from the vault.
    ///
    /// @dev    ─────────────────────────────────────────────────────────────────
    ///         LAYER 2: nonReentrant MUTEX LOCK
    ///         The ReentrancyGuard sets an internal flag to "ENTERED" at the
    ///         top of this function.  If any external call (the .call below)
    ///         tries to re-enter withdraw(), the guard sees "ENTERED" and
    ///         reverts before any code runs.  The flag is cleared on exit.
    ///         ─────────────────────────────────────────────────────────────────
    function withdraw() external nonReentrant {

        // ── CHECKS ────────────────────────────────────────────────────────────
        //    Verify the request is legitimate before touching any state.
        uint256 amount = balances[msg.sender];
        if (amount == 0) revert ZeroBalance();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        //    Update ALL internal state BEFORE making any external call.
        //    This is the "Golden Rule": zero the balance NOW so that even if
        //    somehow a re-entrant call sneaks through the mutex, it sees a
        //    zero balance and cannot withdraw again.
        //
        //    ⭐ KEY LINE: balance → 0 BEFORE the .call
        balances[msg.sender] = 0;
        totalDeposits        -= amount;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        //    Only NOW do we interact with the outside world (send ETH).
        //    At this point the state is already consistent; a re-entrant call
        //    would find a zero balance and revert on the CHECKS step.
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert ETHTransferFailed();

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Withdraw a partial amount from your balance.
    ///
    /// @dev    Same CEI + nonReentrant pattern as withdraw().
    ///         Included to show the pattern scales to partial withdrawals too.
    ///
    /// @param amount  Wei to withdraw (must be ≤ your balance).
    function withdrawPartial(uint256 amount) external nonReentrant {

        // ── CHECKS ────────────────────────────────────────────────────────────
        if (amount == 0)                    revert ZeroDeposit();
        if (balances[msg.sender] < amount)  revert InsufficientBalance();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        balances[msg.sender] -= amount;  // ⭐ deducted BEFORE the .call
        totalDeposits        -= amount;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert ETHTransferFailed();

        emit Withdrawn(msg.sender, amount);
    }

    // ─── Emergency drain (owner only) ─────────────────────────────────────────

    /// @notice Owner can sweep the vault in a genuine emergency.
    /// @dev    CEI + nonReentrant applied here too — the pattern is universal.
    function emergencyWithdraw() external onlyOwner nonReentrant {

        // ── CHECKS ────────────────────────────────────────────────────────────
        uint256 amount = address(this).balance;
        if (amount == 0) revert ZeroBalance();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        totalDeposits = 0;
        // (balances per user not zeroed — this is an emergency escape hatch;
        //  in production you'd iterate or use a "drained" flag.)

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) revert ETHTransferFailed();

        emit EmergencyWithdrawn(owner(), amount);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Returns the caller's current vault balance.
    function myBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    // ─── Receive ──────────────────────────────────────────────────────────────

    /// @dev    Redirect plain ETH sends to deposit() so they are tracked.
    receive() external payable {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
            totalDeposits        += msg.value;
            emit Deposited(msg.sender, msg.value);
        }
    }
}
