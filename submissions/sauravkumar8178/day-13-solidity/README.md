# 🪙 Day 13 — Token Sale (Sell Your Tokens for Ether)

Welcome to **Day 13 of #30DaysOfSolidity**!
In this project, you’ll build a smart contract that allows users to **buy your ERC-20 tokens using Ether**, simulating a **token pre-sale or ICO** model. This task helps you understand **token economics**, **pricing**, and **sale management** in decentralized applications.

---

## 🎯 Objective

Create a token sale system where:

* You set a price for your ERC-20 tokens (tokens per ETH).
* Buyers can send Ether to the contract to purchase tokens.
* The contract holds tokens and transfers them to buyers automatically.
* The owner can withdraw Ether and unsold tokens.

---

## 🧩 Key Features

* **ERC-20 Token Implementation** — A simple mintable token.
* **Token Sale Contract** — Sells tokens for ETH at a fixed rate.
* **Dynamic Pricing** — Owner can update token price anytime.
* **Pause/Resume Sale** — Toggle sale availability.
* **Secure Withdrawals** — Owner can withdraw Ether or remaining tokens.
* **Receive Function** — Allows direct ETH payments to trigger purchases.

---

## ⚙️ How It Works

1. **Deploy Token**

   * Deploy your ERC-20 token (e.g., 1,000,000 tokens).
   * The deployer (owner) receives the full supply.

2. **Deploy Sale Contract**

   * Pass your token’s address and desired token price (tokens per ETH).
   * Example: 1 ETH = 1000 tokens → set `tokensPerEth = 1000 * 10^18`.

3. **Fund Sale Contract**

   * Transfer tokens from your wallet to the sale contract.
   * These tokens will be available for buyers.

4. **Buy Tokens**

   * Users send Ether to the contract (either via `buyTokens()` or directly).
   * The contract calculates and transfers tokens to the buyer.

5. **Owner Controls**

   * Update price, pause the sale, or withdraw funds/tokens anytime.

---

## 🧮 Example Calculation

If:

* `tokensPerEth = 1000 * 10^18`
* Buyer sends `0.5 ETH`

Then:

```
0.5 * 1000 = 500 tokens
```

The buyer receives **500 tokens** automatically.

---

## 🛡️ Security Notes

* Always **fund the sale contract** before opening it for buyers.
* Ensure **sufficient tokens** are available for expected sales.
* Withdraw Ether and remaining tokens only after the sale is complete.
* Consider adding features like:

  * **Whitelist buyers**
  * **Purchase caps**
  * **Timelocks or vesting**
  * **Dynamic pricing with oracles**

---

## 🧠 What You’ll Learn

* How ERC-20 tokens are priced and exchanged for ETH.
* How to build safe payment flows using `msg.value`.
* How to handle withdrawals securely.
* The importance of modifiers and owner privileges in Solidity.

---

## 🧰 Tools Used

* **Solidity 0.8.19+**
* **Remix IDE** for deployment and testing
* **MetaMask** or any Web3 wallet for buying tokens

---

## 🚀 Steps to Run in Remix

1. Open [Remix IDE](https://remix.ethereum.org)
2. Create two files: `MyToken.sol` and `TokenSale.sol`
3. Compile both using Solidity 0.8.19
4. Deploy `MyToken` → note down the contract address
5. Deploy `TokenSale` → provide token address & tokens per ETH
6. Transfer tokens to the sale contract
7. Send ETH using `buyTokens()` to purchase tokens

---

## 📘 Learning Outcome

By completing this task, you’ll understand:

* Token economics and sale design
* Managing smart contract balances
* Ether-to-token conversion logic
* Secure withdrawal patterns

