# 💸 Day 23 of #30DaysOfSolidity — Build a DeFi Lending & Borrowing System

## 🚀 Introduction

In this challenge, we’ll build a **decentralized lending and borrowing system**, a core component of DeFi protocols like **Aave** and **Compound**.

Users will be able to:

* **Supply (lend)** digital assets and earn interest.
* **Borrow** assets by providing **collateral**.
* **Accrue interest** over time.
* **Liquidate** unhealthy loans.

This project demonstrates the foundations of decentralized finance — understanding interest rates, collateralization, liquidation, and safe lending mechanics on-chain.

---

## 🎯 Learning Goals

By completing this project, you’ll learn:

* How to manage **lending pools** and track liquidity.
* How to implement **borrowing with collateral** and **Loan-to-Value (LTV)** ratios.
* How to **calculate and accrue interest** dynamically.
* How to handle **liquidations** when borrowers fall below safety thresholds.
* How DeFi protocols like **Aave**, **Compound**, and **MakerDAO** manage risk and yield.

---

## 🧠 Concepts Covered

### 1. Lending Pools

A pool where users supply tokens. These tokens can be borrowed by others, earning interest for lenders.

### 2. Borrowing with Collateral

Borrowers must deposit another token as collateral (e.g., borrow DAI by locking ETH). The system enforces an **LTV ratio** — for example, with 50% LTV, $100 of ETH collateral allows $50 of DAI borrowing.

### 3. Interest Rate Model

Borrowers pay interest per block. Interest is calculated using a **utilization-based rate model**, meaning higher pool utilization → higher interest rate.

### 4. Accrued Interest

Over time, the system updates total borrows and borrow indexes based on block intervals, ensuring fairness and yield accuracy.

### 5. Liquidations

If collateral value drops below the **liquidation threshold**, anyone can liquidate the borrower by repaying part of their debt in exchange for a portion of the collateral plus a bonus.

---

## ⚙️ System Architecture

### 🧩 Smart Contracts

1. **LendingPool** — Core logic for supply, borrow, repay, withdraw, and liquidation.
2. **InterestRateModel** — Defines how interest scales with utilization.
3. **PriceOracle** — Provides token price data (e.g., from Chainlink).
4. **ERC20Mock** — Mock token for testing supply and collateral.

### 💰 Core Variables

* **totalSupply**: Total assets deposited into the pool.
* **totalBorrows**: Total borrowed principal.
* **borrowIndex**: Scales borrower balances with interest growth.
* **ltv**: Loan-to-Value ratio (e.g., 50%).
* **liquidationThreshold**: Limit beyond which positions can be liquidated.
* **liquidationBonus**: Percentage bonus given to liquidators.

---

## 🔁 System Flow

### 🪙 1. Supplying Assets

Users deposit tokens into the lending pool. These tokens become available for borrowers. Suppliers earn yield from interest paid by borrowers.

### 🧱 2. Providing Collateral

Borrowers must first deposit another asset as collateral (e.g., WETH, wBTC).

### 💵 3. Borrowing Assets

Users can borrow tokens based on the value of their collateral.
For example:

> Deposit $200 of ETH → Borrow up to $100 of DAI (at 50% LTV).

The protocol checks the borrower’s health factor before allowing the loan.

### 📈 4. Interest Accrual

Interest grows per block using a dynamic formula:

> **Interest = BaseRate + (Slope × Utilization)**

Borrowers’ debts automatically grow with time, and lenders’ earnings increase accordingly.

### 💰 5. Repayment

Borrowers can repay any portion of their debt at any time. Upon repayment, interest and principal are adjusted.

### ⚠️ 6. Liquidation

If a borrower’s collateral value drops below the threshold:

* A **liquidator** can repay part of their debt.
* The liquidator receives a portion of the borrower’s collateral (plus a small bonus).
* The protocol remains solvent.

---

## 📊 Example Scenario

1. Alice deposits **1000 DAI** to earn interest.
2. Bob deposits **1 ETH** as collateral (worth $2000).
3. Bob borrows **1000 DAI** against his ETH (50% LTV).
4. ETH price drops to $1200. Bob’s position becomes risky.
5. A liquidator repays Bob’s DAI debt and seizes part of his ETH collateral.

---

## 🧩 Key Components Explained

### 🔸 Loan-to-Value (LTV)

Determines how much a user can borrow against their collateral.

> If LTV = 50%, $2000 collateral → max $1000 borrow.

### 🔸 Liquidation Threshold

If a user’s borrowed amount exceeds this ratio, their position becomes **liquidatable**.

### 🔸 Liquidation Bonus

When liquidating, the liquidator gets slightly more collateral than the debt repaid — usually 5–10% as incentive.

### 🔸 Borrow Index

A scaling factor that keeps track of accumulated interest over time across all borrowers.

---

## 🧮 Interest Rate Model (Simple Linear)

A simple model calculates borrow rates dynamically:

> **Borrow Rate = Base Rate + Slope × Utilization**

Where:

* **Utilization = totalBorrows / (cash + totalBorrows)**
* High utilization = higher rates (to encourage more supply).

---

## 🧱 Smart Contract Stack

| Contract              | Responsibility                                          |
| --------------------- | ------------------------------------------------------- |
| **LendingPool**       | Manages deposits, borrows, repayments, and liquidations |
| **InterestRateModel** | Calculates per-block interest based on utilization      |
| **PriceOracle**       | Provides token prices to calculate LTV and health       |
| **ERC20Mock**         | Simulates real tokens for testing                       |

---

## 🧪 Testing with Foundry

You can test:

* Deposits and withdrawals
* Collateral deposits and borrows
* Interest accrual over multiple blocks
* Collateral liquidations when prices drop

Run tests with:

```bash
forge test
```

---

## 🧰 Tools & Stack

* **Solidity (v0.8.20+)** — Smart contract language
* **Foundry** — Testing and deployment
* **Ethers.js** — Frontend interactions
* **Chainlink / Mock Oracles** — Price data

---

## 🌐 Frontend Integration (Ethers.js Example)

Use Ethers.js to interact with your pool:

* `supply(token, amount)`
* `depositCollateral(token, amount)`
* `borrow(token, amount)`
* `repay(token, borrower, amount)`
* `liquidate(repayToken, borrower, repayAmount, collateralToken)`

A clean React interface could display:

* Collateral balance
* Borrowed amount
* Health factor
* Available liquidity

---

## 🔒 Security Considerations

* Add **Reentrancy Guards** to all external functions.
* Use **SafeERC20** for token transfers.
* Verify **price oracle integrity** (prevent manipulation).
* Implement **access control** for admin parameters.
* Enforce proper **interest index accounting** for fairness.

---

## 🧩 Extensions & Next Steps

Once you understand the basics, expand your protocol:

1. Add **aTokens** (interest-bearing tokens) to represent supplied assets.
2. Integrate **Chainlink Oracles** for live price data.
3. Add **multiple collateral types**.
4. Implement **governance** for parameter updates.
5. Introduce **flash loans** and **stable borrow rates**.

---

## 🏁 Summary

You’ve just built the foundation of a **DeFi lending protocol** — the backbone of decentralized finance.

By understanding these mechanics, you now have the skills to explore:

* **Yield farming protocols**
* **Collateralized stablecoins**
* **Interest-bearing tokens**
* **Cross-chain lending systems**

This project bridges the gap between **traditional finance concepts** and **decentralized smart contract logic**.

