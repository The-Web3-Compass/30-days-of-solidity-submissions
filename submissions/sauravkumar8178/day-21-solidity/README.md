# 🎨 Day 21 of #30DaysOfSolidity — Create Your Own Digital Collectibles (ERC-721 NFTs)

## 🧩 Overview

In this project, we build **digital collectibles** (NFTs) by implementing the **ERC-721 standard**.
Each collectible is a **unique token** that holds metadata — similar to digital trading cards, artwork, or in-game assets.

This task demonstrates:

* How ERC-721 tokens work
* How to mint unique digital assets
* How to store and retrieve metadata (using token URIs)
* How to interact with the NFT smart contract via a simple frontend

---

## ⚙️ Tech Stack

| Layer              | Technology             |
| ------------------ | ---------------------- |
| **Smart Contract** | Solidity + Foundry     |
| **Token Standard** | ERC-721 (OpenZeppelin) |
| **Frontend**       | React + Ethers.js      |
| **Blockchain**     | Local network (Anvil)  |
| **Testing**        | Forge (Foundry)        |

---

## 🏗️ Features

✅ Implements the **ERC-721 standard** for NFTs
✅ Stores metadata using **token URIs (e.g., IPFS links)**
✅ Includes **minting functionality** to create new collectibles
✅ Displays **total minted supply**
✅ Simple **React + Ethers.js** interface for minting NFTs
✅ Fully **tested** and runs on **local blockchain**

---

## 📁 Project Structure

```
nft-project/
├─ contracts/           # Solidity smart contract (ERC-721)
├─ script/              # Deployment script for Foundry
├─ test/                # Unit tests for contract
├─ frontend/            # React + Ethers.js frontend
├─ foundry.toml         # Foundry configuration
├─ README.md            # Documentation
```

---

## 🚀 Getting Started

### 1️⃣ Clone and Install

```bash
git clone <repo-url>
cd nft-project
forge install OpenZeppelin/openzeppelin-contracts@v4.9.3 --no-git
```

### 2️⃣ Compile Contracts

```bash
forge build
```

### 3️⃣ Run Tests

```bash
forge test
```

### 4️⃣ Start Local Blockchain

```bash
anvil
```

### 5️⃣ Deploy Contract

```bash
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

### 6️⃣ Launch Frontend

```bash
cd frontend
npm install
npm run dev
```

Visit **[http://localhost:5173](http://localhost:5173)** and connect your wallet to start minting NFTs.

---

## 🌐 Frontend Features

The frontend allows you to:

* Connect your MetaMask wallet
* Input a metadata URI (e.g., IPFS link)
* Mint a new NFT directly from the browser
* Display transaction status and confirmation

---

## 🧠 Concepts Learned

* Understanding **ERC-721** and NFT token structure
* Using **OpenZeppelin libraries** for security and simplicity
* Deploying and interacting with contracts via **Foundry scripts**
* Connecting smart contracts with **React and Ethers.js**
* Managing metadata through **tokenURI**

---

## 🏁 Summary

By completing this project, you’ve built a complete **NFT Collectibles DApp** — from writing and deploying an ERC-721 contract to minting NFTs through a React interface.
You now understand how **digital ownership** and **unique metadata** form the foundation of the NFT ecosystem.

