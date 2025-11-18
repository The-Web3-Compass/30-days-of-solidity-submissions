# 🏰 Day 20 of #30DaysOfSolidity — Secure Digital Vault (FortKnox)

## 🎯 Project Goal

Build a **secure digital vault** where users can **deposit and withdraw tokenized gold (or any valuable ERC-20 asset)** — just like a decentralized version of *Fort Knox*. The focus is on **preventing reentrancy attacks**, one of the most common vulnerabilities in smart contracts.

---

## 🔐 Overview

In this project, users interact with a **Vault smart contract** to deposit and withdraw ERC-20 tokens. The contract ensures that no malicious actor can exploit the withdrawal logic to repeatedly drain funds by using **Solidity’s `nonReentrant` pattern** and the **Checks-Effects-Interactions (CEI)** principle.

---

## 🧩 Key Concepts

### 1. **Reentrancy Attack**

A reentrancy attack occurs when a malicious contract repeatedly calls a vulnerable function *before* the previous execution completes — usually during an external token transfer. This allows attackers to withdraw more funds than they actually have.

### 2. **`nonReentrant` Modifier**

Implements a **mutex (lock mechanism)** that blocks nested calls into sensitive functions.
When one `nonReentrant` function is executing, another cannot be re-entered until it’s finished.

### 3. **Checks-Effects-Interactions Pattern**

The CEI pattern ensures:

* ✅ **Checks** — Validate input and preconditions
* ⚙️ **Effects** — Update state (like balances)
* 🔗 **Interactions** — Finally, interact with external contracts (like transferring tokens)

Following this pattern makes contracts more predictable and less vulnerable.

---

## ⚙️ Features

* Deposit and withdraw ERC-20 tokens safely
* Protection from **reentrancy attacks**
* Uses **Checks-Effects-Interactions** for secure logic
* Optional **pause mechanism** for emergencies
* **Owner-controlled rescue** for stuck tokens
* Emits **events** for transparency

---

## 🧠 What You’ll Learn

* How reentrancy attacks work and how to stop them
* Writing a **secure withdrawal function**
* Implementing a **custom `nonReentrant` modifier**
* Following **Solidity security best practices**
* Managing **user balances** safely in smart contracts
* Using **OpenZeppelin’s SafeERC20** utilities

---

## 🧪 Testing Scenarios

* ✅ Deposit and withdraw normal flow
* 🚫 Reentrancy attack attempt (should fail)
* 🚫 Withdraw more than balance (should revert)
* 🛑 Pause vault and block deposits/withdrawals
* ⚙️ Owner rescuing tokens safely

---

## 🔍 Security Practices Implemented

1. **nonReentrant modifier** using a lock variable
2. **Checks-Effects-Interactions** order strictly followed
3. **SafeERC20** used for all token transfers
4. **Pause and Rescue** mechanisms for emergencies
5. **No loops** over user-controlled data
6. **Events** emitted for all state-changing actions

---

## ⚠️ Before Mainnet Deployment

* [ ] Run reentrancy tests with malicious contracts
* [ ] Perform external security review or audit
* [ ] Verify the contract on Etherscan/Polygonscan
* [ ] Use a **multisig wallet** for owner functions
* [ ] Lock down emergency functions with a **time delay**

---

## 💡 Real-World Analogy

Think of this vault as a **digital Fort Knox** — everyone can lock up their gold safely, but withdrawals are strictly monitored to prevent anyone from sneaking extra gold out.
Security first, always.

---

## 🚀 Future Enhancements

* Support for **EIP-2612 permit deposits** (gasless approvals)
* Add **timelocked withdrawals** for higher security
* Create a **front-end dashboard** to visualize deposits and balances
* Add **proof-of-reserve tracking** via Chainlink oracles

---

## 🧭 Learning Outcome

By completing this project, you’ll deeply understand:

* How **reentrancy vulnerabilities** occur
* How to design **secure, defensive contracts**
* How to apply **Solidity best practices** for financial dApps

---

## 📘 Summary

**FortKnoxVault** is a secure token vault built with Solidity that demonstrates how a simple function can become a target for attacks — and how proper design (using `nonReentrant` and CEI) protects users and assets.

This project is a vital step in learning to **build safe smart contracts** for DeFi and beyond.

