# 🪙 Day 12 — Building an ERC-20 Token (30DaysOfSolidity)

## 🧩 Project Overview

In this project, we built a **basic ERC-20 token**, the standard for fungible tokens on the Ethereum blockchain.
This token can be transferred between users, approved for spending by third parties, and managed securely by its owner — similar to creating your own **in-game currency or digital coin**.

The goal was to understand how fungible tokens work, what makes them ERC-20 compliant, and how to implement standard functions and events.

---

## 🎯 Learning Objectives

By completing this project, you will learn:

* The **ERC-20 standard** and its required functions & events
* How to **track balances and allowances**
* How **`transfer`**, **`approve`**, and **`transferFrom`** work
* The role of **minting and burning** in token supply management
* How to test and deploy an ERC-20 token using **Hardhat** and **ethers.js**

---

## 🏗️ Features Implemented

✅ ERC-20 compliant interface
✅ Transfer & Approval functionality
✅ Allowance tracking between users
✅ Owner-only mint and burn
✅ Ownership transfer system
✅ Event logging for `Transfer` and `Approval`
✅ Unit tests for transfers, approvals, and supply changes

---

## 🧠 Concepts Covered

### 🔹 ERC-20 Standard

The ERC-20 interface defines six core functions and two events that every fungible token must follow:

* `totalSupply()`
* `balanceOf(address)`
* `transfer(address, uint256)`
* `approve(address, uint256)`
* `allowance(address, address)`
* `transferFrom(address, address, uint256)`
* Events: `Transfer`, `Approval`

### 🔹 Tokenomics Example

* **Name:** DayToken
* **Symbol:** DAY
* **Decimals:** 18
* **Initial Supply:** 1,000,000 DAY (minted to the owner)

---

## 🔐 Security Considerations

* Mint and burn functions are **restricted to the owner**.
* Always **avoid exposing private keys** in deployment scripts.
* Consider using **timelocks, multisig, or governance contracts** for managing ownership.
* For production deployments, prefer **OpenZeppelin’s audited ERC-20** implementation.

---

## 🧪 Testing Summary

Tests cover:

* Token metadata (name, symbol, decimals)
* Balance updates after transfers
* Approval and allowance mechanics
* Mint and burn functionality
* Reverts for invalid transfers and unauthorized actions

---

## 🚀 What’s Next?

Now that you’ve created a basic ERC-20 token:

* Experiment with **burnable**, **pausable**, or **mintable** extensions
* Add **metadata URIs** or **governance logic**
* Integrate your token into a **dApp frontend** or a **DeFi protocol**

---

## 🏁 Wrap-Up

You’ve successfully created your own **digital currency** — the foundation of countless Web3 projects.
From here, you can expand it into NFTs, DAOs, or DeFi ecosystems.

