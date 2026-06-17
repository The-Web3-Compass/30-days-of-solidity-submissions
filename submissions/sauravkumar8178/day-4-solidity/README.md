# 🪙 Day 4: Build a Basic Auction Smart Contract

## 🎯 Task

Create a basic auction! Users can bid on an item, and the highest bidder wins when time runs out. You’ll use `if/else` to determine the winner based on the highest bid and track time using the blockchain’s clock (`block.timestamp`).

This is like a simple version of **eBay on the blockchain**, showing how to manage logic based on **conditions and time**.

---

## 🧠 Learning Objectives

* Understand how to handle **time-based logic** using `block.timestamp`.
* Learn to implement **conditional statements** (`if/else`) in Solidity.
* Practice storing and comparing **bids and bidders**.
* Understand **auction flow** (start → bid → end → winner).

---

## 🧩 Smart Contract Breakdown

### Key Features

* The auction starts when the contract is deployed.
* Users can place bids higher than the current highest bid.
* Auction ends after a set duration.
* The highest bidder wins when time runs out.
* Owner can withdraw funds after the auction ends.

### Key Variables

* `owner`: The auction creator.
* `highestBid`: Tracks the highest bid.
* `highestBidder`: Stores the address of the highest bidder.
* `auctionEndTime`: The timestamp when the auction ends.

### Key Functions

1. **`bid()`** → Allows users to bid with Ether.
2. **`endAuction()`** → Ends the auction and transfers the winning bid to the owner.
3. **`getTimeLeft()`** → Returns remaining auction time.

---

## ⚙️ How It Works

1. The auction starts when the contract is deployed.
2. Anyone can call the `bid()` function with a higher bid than the previous one.
3. After time expires, the owner calls `endAuction()` to finalize the result.
4. The highest bidder is declared the winner, and funds go to the owner.

---

## 🧪 Example Flow

1. Deploy the contract with a duration (e.g., 1 minute).
2. User A bids **1 ETH** → `highestBid = 1 ETH`.
3. User B bids **2 ETH** → `highestBid = 2 ETH`.
4. Wait until auction time expires.
5. Call `endAuction()` → User B wins.

---

## 🧰 Technologies Used

* Solidity
* Remix IDE / Hardhat
* Ethereum Blockchain

---

## 📦 Repository

🔗 [Day-4-Solidity Auction Smart Contract](https://github.com/sauravkumar8178/30-days-of-solidity-submissions/tree/main/submissions/sauravkumar8178)

---

## 🏁 Outcome

By completing this project, you’ll understand how to:

* Manage blockchain time using `block.timestamp`.
* Handle user bids and compare values securely.
* Implement conditional statements to control contract flow.
* Create logic-driven dApps like auctions, lotteries, and games.

