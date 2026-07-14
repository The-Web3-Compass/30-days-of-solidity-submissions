# Week 1 — Solidity Fundamentals (Day 5)
## Challenge: AdminOnly.sol (Treasure Chest)

Author: Nadiatus Salam  
Contract file: `AdminOnly.sol`

### Challenge Recap
Practice basic access control using:
- `modifier` for ownership checks
- `msg.sender` to identify the caller
- if/else flow to enforce business rules

Build a “treasure chest” where only the owner can manage treasure and permissions, while users can withdraw only if approved and not yet withdrawn.

---

## Contract Overview

`AdminOnly` is a minimal access-controlled vault with:
- Ownership captured at deployment; admin capabilities gated by `onlyOwner`.
- ETH treasury managed by the owner (`addTreasure` or `receive()` from owner).
- Per-user allowance in wei; one-time withdrawals enforced via `hasWithdrawn`.
- Secure withdrawal mechanics with non-reentrancy and checks-effects-interactions.
- Ownership transfer and administrative resets.

### Key State
- `owner`: current admin of the chest
- `allowance[user]`: approved amount (wei) for a user
- `hasWithdrawn[user]`: whether the user already took their allowance
- `reservedAllowance`: total unclaimed user allowances (treasury must not drop below this)
- `locked`: private reentrancy flag (nonReentrant)

### Events
- `OwnershipTransferred(previousOwner, newOwner)`
- `TreasureAdded(from, amount)`
- `AllowanceSet(user, amount)`
- `AllowanceCleared(user)`
- `WithdrawalByUser(user, amount)`
- `WithdrawalByOwner(owner, amount)`
- `WithdrawalReset(user)`

---

## File Header (SPDX + Pragma)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
```
- MIT license, and Solidity 0.8.x safety checks enabled by default.

## NatSpec
- Contract header uses `@title`, `@notice`, `@dev`.
- Functions include concise purpose notes for readability and tooling.

---

## Core Functions

### Owner Deposit
```solidity
function addTreasure() external payable onlyOwner
```
- Owner deposits ETH into the vault.
- Reverts if `msg.value == 0`.

### Set/Clear Allowance
```solidity
function setAllowance(address user, uint256 amount) external onlyOwner
function clearAllowance(address user) external onlyOwner
```
- Sets a user’s one-time withdrawal amount (in wei) and resets `hasWithdrawn` to `false`.
- Clearing sets allowance to 0.

### User Withdraw (One-Time)
```solidity
function withdraw() external
```
- Requires allowance > 0 and not withdrawn yet.
- Non-reentrant; zeroes state before transferring ETH.
- Decreases `reservedAllowance` on success; restores it if transfer fails (reverts `WithdrawFailed`).

### Owner Withdraw
```solidity
function ownerWithdraw(uint256 amount) external onlyOwner
```
- Owner can extract ETH from the vault if balance is sufficient.
- Safeguard: post-withdraw balance must be >= `reservedAllowance` to protect users’ unclaimed funds.

### Reset Withdrawal Flag
```solidity
function resetWithdrawal(address user) external onlyOwner
```
- Resets `hasWithdrawn[user]` (e.g., for a new round), does not change allowance.

### Transfer Ownership
```solidity
function transferOwnership(address newOwner) external onlyOwner
```
- Transfers admin control to another address.

### Receive/Fallback
- `receive()` accepts ETH only from the owner and emits `TreasureAdded`.
- `fallback()` reverts to prevent unexpected calls/ETH.

---

## Security & Best Practices

- `onlyOwner` modifier for admin-only actions.
- Non-reentrancy guard (boolean lock) on ETH-transferring functions.
- Checks-Effects-Interactions pattern in `withdraw()` to mitigate reentrancy.
- Custom errors reduce gas on failing paths, including `WithdrawFailed` for failed sends.
- Tracks `reservedAllowance` and prevents owner withdrawals that would underfund users.
- Direct ETH from non-owner is blocked in `receive()` and `fallback()`.

---

## Quick Test (Remix)

1. Open https://remix.ethereum.org  
2. Create `AdminOnly.sol` and paste the code.
3. Compile with `0.8.24`.
4. Deploy; the deployer becomes `owner`.

Interactions:
- Owner: call `addTreasure()` with value (e.g., 1 ether).
- Owner: call `setAllowance(USER, amount)` (e.g., 0.25 ether).
- USER: from USER account, call `withdraw()` → receives 0.25 ether; second call should revert `AlreadyWithdrawn`.
- Owner: call `resetWithdrawal(USER)`; optionally call `setAllowance(USER, amount)` again for another round.
- Owner: call `ownerWithdraw(amount)` to move ETH back to owner.
- Non-owner sending ETH directly to contract should revert; owner’s direct send is accepted and emits `TreasureAdded`.

---

## Notes / Extensions (Optional)
- Add batch allowance setting for multiple users.
- Add pause/unpause mechanism for emergency stops.
- Add ERC20/ERC721 support for non-ETH treasure (requires token interfaces).