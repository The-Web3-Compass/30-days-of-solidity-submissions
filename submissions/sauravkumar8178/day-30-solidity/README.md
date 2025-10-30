# Day 30 — Simple Token Exchange (AMM)

This project demonstrates how to build a **simple decentralized exchange** that allows users to trade tokens through a **constant-product Automated Market Maker (AMM)** model. It’s a lightweight version of Uniswap V2 designed purely for learning.

---

## 🧩 Overview

This project implements the concept of a **liquidity pool**, where users deposit two tokens and receive **liquidity tokens (LP tokens)** representing their share. Traders can then swap between these tokens directly through the pool without needing an order book.

---

## ⚙️ Features

* Add and remove liquidity
* Swap between two ERC20 tokens
* 0.3% swap fee distributed to liquidity providers
* Constant product formula `x * y = k` for price balance
* Factory pattern for creating new token pairs
* Fully compatible with Foundry

---

## 🏗️ Architecture

**Contracts included:**

1. **ExchangeFactory** — Deploys and tracks exchange pairs.
2. **ExchangePair** — Handles liquidity, swaps, and reserves.
3. **ERC20** — Minimal token used for LP representation.
4. **MockERC20** — Mintable test token for simulating trades.

---

## 📂 Project Structure

```
day-30-solidity/
├─ src/
│  ├─ ERC20.sol
│  ├─ MockERC20.sol
│  ├─ ExchangeFactory.sol
│  └─ ExchangePair.sol
├─ script/
│  └─ Deploy.s.sol
├─ test/
│  └─ Exchange.t.sol
├─ remappings.txt
└─ README.md
```

---

## 🧠 How It Works

1. **Liquidity Provision**
   Users supply equal values of two tokens to the pool and receive LP tokens representing their ownership.

2. **Swapping**
   Traders send one token and receive the other, with prices determined by the constant-product formula. A 0.3% fee is applied to each trade.

3. **Removing Liquidity**
   Liquidity providers can burn LP tokens to reclaim their share of the reserves (plus fees).

4. **Invariant Check**
   The pool maintains the equation `x * y = k` to ensure balance and prevent arbitrage exploits.

---

## 🧪 Setup & Usage

**Requirements:**

* [Foundry](https://book.getfoundry.sh/) installed
* Solidity 0.8.19
* An RPC URL (for deployment)

**Commands:**

* Run tests:

  ```bash
  forge test -vv
  ```
* Deploy contract:

  ```bash
  forge script script/Deploy.s.sol:DeployScript --broadcast --rpc-url <YOUR_RPC_URL>
  ```

---

## ⚠️ Notes

* This is an **educational prototype** — not production-ready.
* No oracle, slippage protection, or flash-loan defense implemented.
* Always test thoroughly before using on live networks.

---

## 🚀 Future Enhancements

* Add **price oracles (TWAP)** for external integrations
* Introduce **permit approvals (EIP-2612)** for gasless liquidity actions
* Integrate **fee collection mechanisms**
* Add **frontend dashboard** for visualization and swaps

