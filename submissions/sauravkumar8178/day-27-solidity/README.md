# 🪙 Day 27 — Staking & Yield Farming

## 🎯 Task

Build a system for earning rewards by staking tokens.
You’ll learn how to distribute rewards and implement yield farming — like a **digital savings account** that pays **interest in tokens**.

---

## 📘 Overview

In this project, you’ll create a **Staking Rewards System** in Solidity.
Users can **stake tokens** (e.g., an ERC-20 token) and **earn rewards** in another token over time.
This project demonstrates **yield farming mechanics**, one of the core pillars of DeFi (Decentralized Finance).

---

## ⚙️ What You’ll Learn

* How token staking works on Ethereum
* Reward distribution using `rewardPerToken` logic
* Tracking user balances and time-weighted rewards
* Safe deposit, withdrawal, and reward claiming
* Preventing reentrancy and other common attack vectors
* Managing reward rates and reward pool top-ups

---

## 🧩 Key Features

* Stake any ERC-20 token
* Earn rewards in another ERC-20 token
* Adjustable reward rates (set by owner/governance)
* Accurate user accounting (no looping over users)
* Safe and gas-efficient implementation
* Emergency withdrawal option
* Events for transparency and tracking

---

## 🧱 Project Architecture

**Core Contracts**

* **StakingRewards** – Handles staking, withdrawal, reward calculation, and distribution
* **MockERC20** – Test token for both staking and reward purposes
* **RewardDistributor (optional)** – Manages periodic top-ups for rewards

**Libraries Used**

* OpenZeppelin’s `SafeERC20`, `IERC20`, `Ownable`, and `ReentrancyGuard`

---

## 🧮 Reward Calculation Logic

The reward system is based on the **`rewardPerToken`** model:

* Each staker earns rewards proportional to the time and amount of tokens staked.
* Rewards accumulate continuously based on the configured reward rate.
* Users can claim rewards anytime without affecting others.

This ensures fairness and scalability even with thousands of stakers.

---

## 🚀 Setup & Deployment (Using Foundry)

1. **Install Foundry**

   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Build the project**

   ```bash
   forge build
   ```

3. **Run tests**

   ```bash
   forge test
   ```

4. **Deploy**

   ```bash
   forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
   ```

5. **Initialize Rewards**

   * Transfer reward tokens to contract
   * Call `notifyRewardAmount(reward, duration)` from the owner account

---

## 💻 User Flow

1. **Stake Tokens**

   * Approve staking contract
   * Call `stake(amount)`

2. **Earn Rewards**

   * Rewards accumulate automatically over time

3. **Claim Rewards**

   * Call `getReward()` to receive your earned tokens

4. **Withdraw**

   * Call `withdraw(amount)` or `exit()` to withdraw and claim simultaneously

---

## 🔒 Security Measures

* ReentrancyGuard to prevent attacks
* SafeERC20 for secure token transfers
* Owner-only reward configuration
* Recover accidentally sent tokens (non-core assets)
* No loops for scalability

---

## 🧠 Testing Recommendations

Test with:

* Multiple users staking at different times
* Different reward rates and durations
* Emergency withdraw edge cases
* Reward rate changes mid-cycle
* Precision tests with small rewards over long durations

---

## 💡 Ideas for Extension

* Multi-pool staking (MasterChef style)
* NFT-based reward boosts
* Tiered or time-locked staking (e.g., 30/60/90 days)
* Integrate with a frontend using Ethers.js or Wagmi
* Chainlink Automation to auto-refresh rewards

