# 🪙 Day 29 of #30DaysOfSolidity — Build a Stablecoin

## 🎯 Goal

Build a **digital currency that maintains a stable value** using peg mechanisms.
You’ll learn how to create a simple stablecoin system backed by collateral and managed by oracles — similar to how **DAI or USDC** maintain price stability.

---

## 🧩 Concept Overview

A **Stablecoin** is a cryptocurrency pegged to a stable asset (like USD).
There are different types of peg mechanisms:

* **Fiat-collateralized:** Backed 1:1 by reserves in banks (e.g., USDC).
* **Crypto-collateralized:** Backed by volatile crypto assets with over-collateralization (e.g., DAI).
* **Algorithmic:** Stabilized through smart contracts adjusting supply/demand (less common today).

In this project, we implement a **crypto-collateralized stablecoin** backed by assets like ETH or any ERC20.

---

## 🧠 What You’ll Learn

✅ How stablecoins maintain price stability
✅ How to use **Chainlink Oracles** for real-time asset pricing
✅ How to build **minting and redeeming mechanisms**
✅ How to ensure **over-collateralization (e.g., 150%)**
✅ How to manage treasury and governance roles

---

## ⚙️ Project Structure

```
day-29-stablecoin/
├─ src/
│  ├─ StableUSD.sol           # ERC20 stablecoin contract
│  ├─ OracleManager.sol       # Handles oracle price feeds
│  ├─ CollateralPool.sol      # Core logic for mint/redeem
│  ├─ MockOracle.sol          # Local testing oracle
│  ├─ Treasury.sol            # Manages reserves & burns
│  └─ interfaces/
│     └─ IAggregatorV3.sol    # Chainlink-like interface
├─ script/
│  └─ Deploy.s.sol            # Foundry deployment script
├─ test/
│  └─ Stablecoin.t.sol        # Foundry tests
├─ foundry.toml
└─ README.md
```

---

## 🏗️ Step-by-Step Implementation

1. **Create the Stablecoin**

   * ERC20 token with mint and burn permissions.
   * Roles managed through `AccessControl`.

2. **Integrate OracleManager**

   * Fetches live asset prices using Chainlink (or mocks in local tests).

3. **Develop CollateralPool**

   * Users deposit collateral (like WETH).
   * Stablecoin minted at a safe ratio (e.g., 150% collateralized).
   * Users can redeem sUSD for collateral anytime.

4. **Add Treasury**

   * Holds reserves and fees.
   * Authorized to burn excess sUSD or manage buybacks.

5. **Testing with Foundry**

   * Unit tests simulate deposit, mint, and redeem flows.
   * Validate correct price handling and peg logic.

---

## 🧮 Peg Logic Example

If **1 ETH = $1800** and **collateral ratio = 150%**,
then a user depositing **1 ETH** can mint:

```
(1800 * 100 / 150) = 1200 sUSD
```

This ensures the system stays over-collateralized.

---

## 🧪 Testing Commands

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
forge build
forge test -vv
```

You can modify the `MockOracle` price to simulate market fluctuations and observe how minting and redemption adjust accordingly.

---

## 🛡️ Security Considerations

* Use **Chainlink verified oracles** for production.
* Add **liquidation mechanisms** if collateral value drops.
* Include **governance and pause controls**.
* Consider using **SafeMath (>=0.8 has built-in checks)**.

---

## 🚀 Next Steps

* Implement **multi-collateral support** (ETH, DAI, USDC).
* Add **liquidations** for under-collateralized positions.
* Introduce **governance tokens (DAO)** to manage parameters.
* Integrate **Uniswap or Curve** for on-chain stability trades.

---

## 🧭 Key Takeaways

* Stablecoins showcase **real-world DeFi utility**.
* Understanding peg mechanics teaches **monetary design** in smart contracts.
* This project lays the foundation for **DAI-style systems** built on Ethereum.

