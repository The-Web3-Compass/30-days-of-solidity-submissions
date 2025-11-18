# 🪙 Day 5: Solidity Treasure Chest Contract

## 🎯 Task

Build a smart contract that simulates a **treasure chest controlled by an owner**. The owner has full control over the treasure and can manage who is allowed to withdraw from it.

### Key Features

* **Owner Control**:
  The contract starts with an owner who can add treasure, approve users, withdraw treasure, and transfer ownership.

* **Restricted Withdrawals**:
  Only approved users can withdraw treasure, and each user can withdraw **only once** unless the owner resets their status.

* **Ownership Transfer**:
  The owner can safely transfer control of the treasure chest to another address.

* **Reset Withdrawals**:
  The owner can reset a user’s withdrawal permission to allow them to withdraw again.

---

## 🧠 Concepts Learned

### 🔐 Access Control with Modifiers

Use `modifier` to restrict access so that only the owner can execute specific functions.

### 💰 Payable Functions

Learned how to receive and manage Ether inside a smart contract securely.

### 🧾 Mappings

Used mappings to track which users are approved and whether they’ve already withdrawn.

### 👤 Ownership Logic

Implemented functionality to change contract ownership securely.

---

## 🧩 How It Works

1. **Deploy** the contract — the deployer becomes the owner.
2. **Add Treasure** — owner deposits Ether into the chest.
3. **Approve Users** — owner allows specific users to withdraw.
4. **Withdraw** — approved users can withdraw treasure once.
5. **Reset** — owner can reset withdrawal permissions.
6. **Transfer Ownership** — owner can hand over control to another address.

---

## 🧪 Testing Steps

1. Deploy the contract in **Remix IDE**.
2. Use `addTreasure()` to deposit Ether.
3. Approve a user with `approveUser(address)`.
4. Switch to that user’s address and call `withdraw(amount)`.
5. Try withdrawing again — it should fail (already withdrawn).
6. Use `resetWithdrawal(address)` to allow the user again.
7. Use `transferOwnership(address)` to change the contract owner.

---

## 🔗 GitHub Repository

[🔗 View Code on GitHub](https://github.com/sauravkumar8178/30-days-of-solidity-submissions/tree/main/submissions/sauravkumar8178)

---

## ✍️ Summary

This project demonstrates **access control, ownership, and Ether management** in Solidity. It mimics how administrators or game masters might control rewards and permissions in decentralized applications.
