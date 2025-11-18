# 🪙 Day 6: Digital Piggy Bank – Solidity Smart Contract

## 📘 Overview

The **Digital Piggy Bank** is a secure and efficient smart contract built with Solidity that allows users to **deposit and withdraw Ether safely**.
This project demonstrates real-world **Ethereum smart contract principles**, including **balance management**, **event logging**, and **secure Ether handling**.

It’s designed with **industry best practices** such as reentrancy protection, the Checks-Effects-Interactions pattern, and event-driven tracking — making it suitable for both **learning** and **production-ready** decentralized applications (dApps).

---

## 🎯 Objectives

* Learn how to **handle Ether transfers** within a smart contract.
* Understand how to use **`msg.sender`** to identify transaction initiators.
* Implement **secure withdrawals** using **reentrancy guards**.
* Practice **state management** with mappings in Solidity.
* Gain exposure to **event-driven architecture** for transparency and traceability.

---

## 🧠 Key Concepts Covered

* **`payable` functions** – To accept Ether transactions.
* **`mapping(address => uint256)`** – To track balances for each user.
* **Event emission** – To log deposits and withdrawals.
* **Reentrancy protection** – To ensure safe and atomic fund transfers.
* **Safe Ether transfer using `.call`** – Modern and gas-efficient method.

---

## ⚙️ Features

✅ Deposit Ether into a personal balance
✅ Withdraw Ether securely at any time
✅ Track your personal balance
✅ View total Ether stored in the contract
✅ Events for deposit and withdrawal actions
✅ Protected against reentrancy attacks
✅ Fully gas-optimized and Solidity 0.8.20+ compatible

---

## 🧩 Architecture

1. **Users** interact with the contract using MetaMask or any Web3-enabled interface.
2. **Deposits** are handled via `msg.value`, updating the user’s balance.
3. **Withdrawals** follow the Checks-Effects-Interactions pattern to avoid vulnerabilities.
4. **Events** record each deposit and withdrawal, helping with frontend integrations or blockchain analytics.

---

## 🚀 Deployment Steps

1. Open [Remix IDE](https://remix.ethereum.org/).
2. Create a new Solidity file and paste the contract code.
3. Compile using **Solidity 0.8.20** or above.
4. Deploy using the **Injected Web3** environment (e.g., MetaMask).
5. Use the contract interface to deposit and withdraw Ether safely.

---

## 🧪 Testing Suggestions

* Deposit different amounts and confirm balance updates correctly.
* Attempt to withdraw more than your balance (should revert).
* Test multiple user accounts to verify isolated balances.
* Check event logs for each transaction in Remix or Etherscan.

---

## 🔐 Security Considerations

* Implements **nonReentrant modifier** for secure withdrawals.
* Uses **Checks-Effects-Interactions pattern** to prevent reentrancy.
* Ether transfers use **`.call`** for better reliability.
* No hardcoded limits, ensuring full user control of funds.

---

## 🌍 Real-World Applications

This project simulates the foundation of:

* Decentralized banking systems 🏦
* User savings vaults 💰
* Wallet management platforms 🔐
* Educational blockchain demos 🧑‍💻

