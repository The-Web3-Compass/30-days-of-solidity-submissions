# 🗳️ Day 28 — Decentralized Voting System (DAO Governance)

## 🎯 Task Overview

Build a system for voting on proposals. You’ll learn how to create a digital organization where members can vote, demonstrating **decentralized governance**.
It’s like a **digital democracy**, showing how to create **DAOs (Decentralized Autonomous Organizations)**.

---

## 🧠 What You’ll Learn

* How to build a simple **DAO smart contract**
* How to manage **members and proposals**
* How to implement a **voting system**
* How to handle **execution of successful proposals**
* How to set **quorum and voting period**

---

## ⚙️ Key Features

✅ Member management — add and remove DAO members
✅ Proposal creation — members can propose actions
✅ Voting system — one member, one vote
✅ Configurable voting duration and quorum
✅ Proposal execution after successful voting
✅ Event logging for transparency

---

## 📂 Project Structure

```
day-28-solidity/
├─ src/
│  └─ SimpleDAO.sol
├─ test/
│  └─ SimpleDAO.t.sol
├─ script/
│  └─ deploy.s.sol
├─ foundry.toml
└─ README.md
```

---

## 🚀 Setup & Usage

### 1. Install Foundry

Follow the [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation).

### 2. Build Project

```bash
forge build
```

### 3. Run Tests

```bash
forge test -vv
```

### 4. Deploy Script

```bash
forge script script/deploy.s.sol --private-key <YOUR_PRIVATE_KEY> --rpc-url <NETWORK_URL> --broadcast
```

---

## 🔄 Workflow

### Step 1: Add Members

Admin adds new DAO members who can participate in voting.

### Step 2: Create Proposal

A member creates a proposal with:

* **Target address** (contract to interact with)
* **Value** (ETH to send)
* **Calldata** (function to call)
* **Description** (proposal purpose)

### Step 3: Voting Period

Members cast their votes (`for` or `against`) within the allowed time window.

### Step 4: Execution

After the voting period ends:

* If **forVotes ≥ quorum** and **forVotes > againstVotes**, the proposal **passes**.
* Anyone can execute the proposal to perform the described actions.

---

## 🧩 Example Use Case

Imagine a decentralized fund where:

* Members vote to fund a project or upgrade the DAO.
* Each proposal must get enough votes before execution.
* Voting power and proposals are transparent on-chain.

---

## ⚖️ Governance Parameters

| Parameter      | Description                                                   |
| -------------- | ------------------------------------------------------------- |
| `votingPeriod` | Duration (in seconds) for which voting is open                |
| `quorum`       | Minimum number of "for" votes required for a proposal to pass |

---

## 🛡️ Security Considerations

* This is a **learning model**, not production-ready.
* Admin has control over adding/removing members.
* `execute` performs arbitrary calls — ensure proposals are verified.
* Use **timelocks** and **token-based voting** for advanced DAOs.

---

## 🧱 Possible Extensions

✨ Token-based voting using ERC20 snapshot
✨ Timelock for proposal execution delay
✨ Proposal cancellation or expiry
✨ Delegated voting power
✨ Off-chain vote signatures for gasless voting

---

## 🧪 Tech Stack

* **Solidity** (Smart Contracts)
* **Foundry** (Testing and Deployment)
* **Forge Std Library** for testing utilities

---

## 📘 Summary

This project demonstrates the fundamentals of decentralized decision-making through smart contracts. It shows how DAOs can:

* Coordinate members,
* Make transparent proposals,
* Conduct fair votes,
* And execute outcomes automatically on-chain.

This is your foundation for building **governance protocols, DAOs, and on-chain voting systems** 🌐

