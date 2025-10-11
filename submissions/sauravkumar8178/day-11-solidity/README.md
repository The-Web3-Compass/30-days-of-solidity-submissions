# 🏦 Day 11 of #30DaysOfSolidity — Secure Vault with Ownership Control

## 📘 Overview

In this challenge, we build a **Secure Vault** system using Solidity’s **inheritance model**.
The project is split into two smart contracts:

* **Ownable** — provides ownership and access control.
* **VaultMaster** — a secure vault that only the owner (the master key holder) can manage.

This pattern mirrors real-world smart contract development, where **security, modularity, and reusability** are crucial.

---

## 💡 What You’ll Learn

* Implementing **access control** using a base `Ownable` contract.
* Understanding **Solidity inheritance** and code reuse.
* Managing **Ether deposits and withdrawals** securely.
* Using **events** for on-chain transparency.
* Applying **reentrancy protection** for safe fund transfers.

---

## 🔐 Key Features

* **Owner-only withdrawals:** Only the master key holder can withdraw or transfer ownership.
* **Deposit mechanism:** Anyone can deposit Ether to the vault.
* **Inheritance model:** `VaultMaster` inherits logic from `Ownable`.
* **Reentrancy Guard:** Prevents multiple malicious calls.
* **Ownership transfer:** Safe delegation of control to another address.
* **Event logging:** Every deposit, withdrawal, and ownership change is logged on-chain.

---

## ⚙️ How It Works

1. **Deploy the Ownable contract** – automatically sets the deployer as the initial owner.
2. **Deploy VaultMaster** – inherits from Ownable and adds deposit/withdraw functionality.
3. **Depositing Ether** – anyone can send Ether to the contract.
4. **Withdrawing Ether** – only the owner can withdraw or transfer funds.
5. **Transferring Ownership** – ownership can be transferred to another address securely.

---

## 🧪 Testing Scenarios

* ✅ Deposit funds into the vault.
* ✅ Owner withdraws specific or full balance.
* ❌ Non-owners attempting to withdraw should fail.
* ✅ Ownership transfer and renunciation.
* ✅ Reentrancy guard verification.

---

## 🧭 Real-World Relevance

This pattern is widely used in:

* **Treasury and fund management** smart contracts.
* **DAO vaults** and **governance-controlled wallets**.
* **DeFi projects** requiring secure access control.
* Any system where **a single master key holder** manages assets securely.

---

## 🧠 Best Practices

* Use **OpenZeppelin**’s audited `Ownable` and `ReentrancyGuard` in production.
* Avoid keeping large balances in a single address.
* Use **multi-signature wallets** (e.g., Gnosis Safe) for ownership.
* Add **time delays** or **withdrawal limits** for extra safety.
* Regularly audit and test smart contracts.

---

## 🌐 Author

**Saurav Kumar**
🚀 Passionate about Blockchain, Web3, and AI
Follow the #30DaysOfSolidity journey on [Dev.to](https://dev.to/sauravkumar8178)

