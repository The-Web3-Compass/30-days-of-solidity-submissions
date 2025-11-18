# ⚙️ Day 25 of #30DaysOfSolidity — Build an Automated Token Trading System (AMM)

## 🧠 Introduction

Today’s challenge focuses on **building an Automated Market Maker (AMM)** — the backbone of decentralized exchanges like **Uniswap**.
Instead of relying on traditional order books, AMMs use **liquidity pools** and the **constant product formula (x * y = k)** to determine prices dynamically.

You’ll learn how to:

* Create liquidity pools between two ERC20 tokens
* Implement the **constant product formula**
* Enable users to **add liquidity, remove liquidity, and swap tokens automatically**
* Understand how **prices adjust** based on pool balances

---

## 🎯 Objective

To design and deploy a **simple decentralized exchange (DEX)** where:

* Users can deposit two tokens to provide liquidity.
* The system automatically prices trades.
* Traders can swap between tokens.
* Liquidity providers earn a fee on every trade.

---

## 🏗️ Core Concepts

### 1. Liquidity Pools

A **liquidity pool** holds reserves of two tokens, say `TokenA` and `TokenB`.
Liquidity providers deposit both tokens to the pool and receive **LP tokens** representing their share.

Example:
If the pool has 100 TokenA and 200 TokenB, and you add 10 TokenA + 20 TokenB, you own **10% of the pool**.

---

### 2. Constant Product Formula

At the heart of the AMM lies the equation:

```
x * y = k
```

Where:

* `x` = reserve of Token A
* `y` = reserve of Token B
* `k` = constant product

Any trade that changes `x` or `y` must keep `k` constant — ensuring the pool always maintains balance.

---

### 3. Swap Mechanism

When a user swaps one token for another:

* The pool increases the reserve of the input token.
* The output token amount is calculated so that the product `x * y` remains constant.
* A small **swap fee** (e.g., 0.3%) is taken and added to the reserves, rewarding liquidity providers.

---

### 4. Adding and Removing Liquidity

* **Add Liquidity:** Deposit both tokens in proportion to the pool’s current ratio.
  You receive **LP tokens** representing your share.
* **Remove Liquidity:** Burn your LP tokens to withdraw your share of the reserves plus earned fees.

---

## 🔐 Security Considerations

* Use the **Checks-Effects-Interactions** pattern to prevent reentrancy.
* Use **SafeERC20** for token transfers.
* Protect against **flash loan attacks** by considering slippage limits.
* Emit events for all core actions (`AddLiquidity`, `RemoveLiquidity`, `Swap`).

---

## 🧪 Testing Plan

Use **Foundry** for testing and debugging:

* ✅ Add liquidity test: verify reserves and LP token minting.
* ✅ Swap test: check price impact and token balances.
* ✅ Remove liquidity test: ensure withdrawal proportionality.
* ✅ Invariant test: ensure `x * y >= k` after every swap.

---

## 🧰 Tools & Technologies

* **Language:** Solidity
* **Framework:** Foundry (Forge + Cast)
* **Libraries:** OpenZeppelin ERC20
* **Testing:** Foundry test suite
* **Blockchain:** Ethereum / Local Anvil

---

## 🚀 Deployment & Usage (Foundry)

1. Compile the contracts:

   ```bash
   forge build
   ```
2. Run tests:

   ```bash
   forge test
   ```
3. Deploy locally:

   ```bash
   forge script script/DeployAMM.s.sol --fork-url http://127.0.0.1:8545 --broadcast
   ```

---

## 💡 Learning Outcome

By completing this project, you’ll understand:

* The **mathematical logic** behind AMMs
* How **DEX liquidity** works
* How **pricing** and **fees** are calculated automatically
* Real-world DeFi mechanisms like **Uniswap v1**

---

## 🧭 Next Steps

* Add **Router contract** to support multi-pool swaps.
* Implement **LP tokens** as ERC20.
* Introduce **fee mechanism** and **protocol fee collection**.
* Extend to **Uniswap V2-like architecture** with pair factories.

