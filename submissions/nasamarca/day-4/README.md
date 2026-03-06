# Week 1 — Solidity Fundamentals (Day 4)
## Challenge: AuctionHouse.sol

Author: Nadiatus Salam  
Contract file: `AuctionHouse.sol`

### Challenge Recap
Build a simple time‑bound auction to practice:
- if/else statements for control flow
- Time handling with `block.timestamp`
- Basic bidding logic (highest bid wins)

This is a minimal on‑chain “eBay‑style” auction: participants place bids until the deadline; the highest bidder wins when time runs out.

---

## Contract Overview

`AuctionHouse` implements a secure and gas‑aware auction:

- `seller` and `endTime` are set at construction and marked `immutable`.
- Optional rules: `minStartingPrice` and `minIncrement` configurable once by the seller before the first bid.
- Bidders call `bid()` with ETH; the highest bid is tracked and must respect optional rules.
- Outbid participants withdraw their ETH themselves using `withdraw()` (pull‑over‑push).
- Anyone can call `endAuction()` after the deadline to finalize the auction.
- `timeLeft()` lets frontends display remaining time.

### Key State
- `seller`: auction owner
- `endTime`: unix timestamp when the auction ends
- `highestBidder`, `highestBid`: current leader
- `pendingReturns`: refunds for outbid bidders
- `ended`: whether the auction has been finalized

### Events
- `Started(endTime)`
- `BidPlaced(bidder, amount)`
- `Withdrawn(bidder, amount)`
- `Ended(winner, amount)`

---

## File Header (SPDX + Pragma)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
```
- MIT license, compiler with 0.8.x safety checks.

## NatSpec
- Header uses `@title`, `@notice`, `@dev`.
- Functions include concise purpose notes.

---

## Core Functions

### Constructor
```solidity
constructor(uint64 durationSeconds)
```
- Validates `durationSeconds > 0` (reverts otherwise).
- Sets `seller = msg.sender`.
- Sets `endTime = block.timestamp + durationSeconds`.
- Emits `Started(endTime)`.

### Configure Auction (Optional)
```solidity
function configureAuction(uint256 minStartingPrice, uint256 minIncrement) external
```
- Only the seller, only once, before the first bid and before the auction ends.
- Sets optional `minStartingPrice` and `minIncrement` used by `bid()`.
- Emits `Configured(minStartingPrice, minIncrement)`.

### Place a Bid
```solidity
function bid() external payable
```
- Requires: auction not ended, `block.timestamp < endTime`, and caller is not the seller.
- First bid: `msg.value >= minStartingPrice`.
- Subsequent bids: `msg.value >= highestBid + minIncrement`.
- If there was a previous highest bid, it is credited to `pendingReturns[oldBidder]`.
- Updates `highestBidder` and `highestBid`, emits `BidPlaced`.

### Withdraw Refund
```solidity
function withdraw() external
```
- Lets outbid bidders reclaim their ETH.
- Checks‑effects‑interactions: zeroes credit before transfer.
- Reverts and restores state if transfer fails.

### End Auction
```solidity
function endAuction() external
```
- Requires: time passed and not already ended.
- if/else decision:
  - If no bids → winner is `address(0)`.
  - Else → transfers `highestBid` to `seller`.
- Sets `ended = true`, emits `Ended`.

### Time Left
```solidity
function timeLeft() external view returns (uint256)
```
- Returns seconds remaining or `0` if the auction is over.

---

## Security & Best Practices

- Pull‑over‑push refunds: prevents reentrancy on losers’ refunds.
- Checks‑Effects‑Interactions: state updated before external calls.
- Custom errors reduce gas on failures.
- `immutable` for `seller` and `endTime` to reduce storage loads.
- Rejects unexpected ETH via `receive()` and `fallback()`.

---

## Quick Test (Remix)

1. Open https://remix.ethereum.org  
2. Create `AuctionHouse.sol` and paste the contract code.
3. Compile with `0.8.24`.
4. Deploy with `durationSeconds` (e.g., `300` for 5 minutes).
5. Interact:
   - Account A (not seller): call `bid()` sending e.g., `1 ether`.
   - Account B: call `bid()` with `2 ether`.  
     - Account A can now call `withdraw()` to get `1 ether` back.
   - Before deadline: `endAuction()` should revert (`AuctionNotEnded`).
   - After deadline: call `endAuction()` → emits `Ended` and sends ETH to seller.
   - `timeLeft()` shows remaining seconds; becomes `0` after end.

---

## Notes / Extensions (Optional)
- Implemented: configurable minimum starting price and bid increment via `configureAuction`.
- Further ideas: hard cap on max duration, anti‑sniping extensions, or restricting `endAuction()` to the seller (trade‑off with trustless finalization).