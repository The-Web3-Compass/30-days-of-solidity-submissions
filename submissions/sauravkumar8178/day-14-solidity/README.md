# 🏦 Day 14 of #30DaysOfSolidity — Smart Bank with Modular Deposit Boxes

## 🚀 Project Overview

In this challenge, we build a **Smart Bank** that provides users with different kinds of digital deposit boxes — **Basic**, **Premium**, and **Time-Locked**. Each box allows users to securely store their data (or encrypted secrets), transfer ownership, and interact seamlessly through a unified **VaultManager** contract.

The goal of this project is to understand **interface design**, **contract modularity**, and **secure inter-contract communication** in Solidity — key concepts for scalable decentralized applications.

---

## 🎯 Learning Objectives

By completing this project, you’ll learn how to:

* Design and implement a **common interface** for multiple contracts.
* Build **modular smart contracts** that follow the same interaction patterns.
* Use **ownership transfer** mechanisms for asset or access handover.
* Understand how **a manager contract interacts** with sub-contracts safely.
* Apply **best security practices** (access control, time locks, and value transfers).

---

## 🧩 System Architecture

### 🔐 1. Deposit Box Interface (`IDepositBox`)

A universal contract interface defining the required functions:

* `storeSecret(bytes secret)` — Stores encrypted or hashed data.
* `retrieveSecret()` — Allows the owner to access stored data.
* `transferBoxOwnership(address newOwner)` — Transfers ownership securely.
* `owner()` — Returns the current box owner.

All deposit box types must implement this interface to ensure compatibility with the **VaultManager**.

---

### 📦 2. Deposit Box Types

#### 🧱 BasicBox

A simple box that allows users to store and retrieve secrets freely.
Only the **owner** can retrieve the stored data.

#### 💎 PremiumBox

An upgraded version that requires a **fee** to store secrets.
The collected fees can later be withdrawn by the box owner — simulating a **paid storage plan**.

#### ⏳ TimeLockedBox

A time-restricted box where the stored secret can only be accessed **after a specified unlock time**.
Ideal for use cases like **escrow, delayed release, or savings vaults**.

---

### 🗃️ 3. VaultManager

A centralized management contract that:

* Creates and registers all deposit boxes.
* Interacts with any box through the common interface.
* Lets users:

  * Create new boxes (`createBasicBox`, `createPremiumBox`, `createTimeLockedBox`)
  * Store secrets on any box (`storeOnBox`)
  * Retrieve stored data (`retrieveFromBox`)
  * Transfer ownership (`transferBoxOwnership`)

The manager acts like the **bank operator**, handling multiple lockers (boxes) in a unified, secure way.

---

## ⚙️ How It Works

1. **VaultManager** deploys and tracks all deposit boxes.
2. Users can create a new box of any type through the manager.
3. Each box stores encrypted or hashed secrets (for real-world privacy).
4. Owners can retrieve or transfer their boxes to other users.
5. The manager can call box functions without needing to know their internal logic — thanks to the shared interface.

---

## 🧠 Key Concepts Practiced

* Solidity **interfaces and inheritance**
* **Contract composition** & modular architecture
* **Secure access control** (ownership, permissions)
* **ETH value transfers** & payable functions
* **Time-based restrictions** using `block.timestamp`
* **Designing scalable dApp ecosystems**

---

## 🔒 Security Considerations

> ⚠️ **Important:** On-chain data is public. Never store real secrets in plaintext.

* Use **encryption** or **hashing** before storing any sensitive data.
* Apply **Reentrancy Guards** if contracts handle user funds.
* Always **validate ownership** before transferring boxes.
* Use **events** for tracking all state changes (already implemented).

---

## 💡 Example Use Cases

* Digital locker system for confidential documents
* Multi-tier storage service (free, premium, delayed)
* Escrow and inheritance smart contracts
* NFT metadata or encrypted data vaults

---

## 🧾 Suggested Improvements

* Integrate **off-chain encryption** and IPFS storage.
* Add **multi-sig control** for joint ownership.
* Implement **upgradeable contract pattern** (UUPS / Proxy).
* Include **gas optimization** and **role-based access** for enterprise use.

