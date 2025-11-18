# 🏪 Day 26 — NFT Marketplace (Solidity + Foundry)

## 🎯 Introduction

On **Day 26** of #30DaysOfSolidity, we’re building a **decentralized NFT Marketplace** — a platform where users can **buy, sell, and trade NFTs** directly on-chain.

This project demonstrates how to create an open trading environment for digital collectibles while supporting **royalties for creators** and **marketplace fees** for the platform owner.

It’s like creating your own **digital store for NFTs**, powered by smart contracts.

---

## 🚀 What You’ll Learn

* Implementing a **marketplace for ERC-721 NFTs**
* Handling **NFT listings**, **purchases**, and **royalty payments**
* Integrating **ERC-2981** royalty standards
* Managing **marketplace fees** in basis points (bps)
* Applying **security patterns** (reentrancy protection, checks-effects-interactions)
* Using **Foundry** for testing and deployment

---

## ⚙️ Key Features

✅ **NFT Collection**

* ERC-721 token with optional ERC-2981 royalty support
* Supports default and per-token royalties
* Owner-controlled minting

✅ **Marketplace**

* List NFTs for sale with price in ETH
* Cancel listings anytime before a sale
* Buy NFTs directly using ETH
* Automatic **royalty** and **marketplace fee** distribution
* Secure fund transfers using OpenZeppelin’s `ReentrancyGuard` and `Address`
* **Events** for `Listed`, `Bought`, and `Cancelled`

✅ **Royalties (ERC-2981)**

* Compliant with royaltyInfo standard
* Royalties automatically paid to the original creator upon sale

✅ **Marketplace Fee**

* Configurable fee in basis points (e.g., 250 = 2.5%)
* Sent to marketplace owner (admin)

---

## 🧪 Testing with Foundry

### 🧰 Requirements

* [Foundry](https://book.getfoundry.sh/getting-started/installation)
* [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)

### ▶️ Commands

```bash
# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Run tests
forge test -vv
```

### 🧾 What Tests Cover

* Minting and listing NFTs
* Buying NFTs and verifying funds distribution
* Checking royalty and marketplace fee logic
* Canceling listings safely

---

## 💡 Example Scenario

1. The **owner** deploys the NFT collection and marketplace.
2. The owner (creator) mints NFTs with royalties (e.g., 5%).
3. A **seller** lists their NFT for sale at 1 ETH.
4. A **buyer** purchases it:

   * Marketplace fee (e.g., 2.5%) goes to the contract owner.
   * Royalty (e.g., 5%) goes to the creator.
   * Remaining amount goes to the seller.
5. NFT ownership transfers to the buyer — all on-chain!

---

## 🔒 Security Considerations

* **Reentrancy protection** via `nonReentrant` modifier.
* **Checks-Effects-Interactions** pattern before external calls.
* **Royalties capped** to prevent overpayment.
* **Emergency withdrawal** function for admin (owner).

---

## 🧩 Possible Extensions

* Add **ERC-20** token payments instead of only ETH.
* Enable **bidding & auctions** for NFTs.
* Integrate a **frontend** using React + Ethers.js.
* Index **listings** with The Graph for better UI experience.
* Add **lazy minting** and off-chain order signing.

---

## 🧠 Concepts Covered

* ERC-721 standard
* ERC-2981 royalty mechanism
* Marketplace fee calculation
* Secure ETH transfers
* Foundry testing and deployment

---

## 📚 Learning Outcome

By completing this project, you’ll understand how to:

* Build and manage an NFT marketplace smart contract
* Integrate royalty logic with ERC-2981
* Handle on-chain trading flows securely
* Use Foundry to test DeFi/NFT systems end-to-end

---

## 🏁 Conclusion

This project is your **gateway to understanding NFT trading logic** in decentralized ecosystems.
You’ve built a fully functional NFT marketplace that respects creator royalties and platform sustainability — an essential component for any NFT ecosystem.

