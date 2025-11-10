---

#  Day 13 - PreorderTokens.sol

### *Selling ERC20 Tokens for Ether | Token Presale Mechanism*

---

##  Task Overview

Build a smart contract that sells ERC20 tokens in exchange for Ether.
This project demonstrates a **real-world token presale model**, where users buy tokens using ETH, and the contract owner can later withdraw the raised funds.

---

##  Prerequisites

Before running this project, make sure you have:

* **Foundry installed** - [Foundry Book Setup](https://book.getfoundry.sh/getting-started/installation)

  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
* **OpenZeppelin Contracts library** (for ERC20 + Ownable)

  ```bash
  forge install OpenZeppelin/openzeppelin-contracts
  ```

---

---

##  Explanation of Files

* **src/PreorderTokens.sol** - Main ERC20 token sale contract handling token minting, sales, and withdrawals.
* **script/DeployPreorderTokens.s.sol** - Deployment script using Foundry’s `vm.startBroadcast()` and logging deployment info.
* **test/PreorderTokens.t.sol** - Automated test verifying token purchase, withdrawal, and sale toggle behavior.

---

##  foundry.toml 

Defines core Foundry project configuration:

* `src`, `out`, and `libs` folder paths
* Remapping for `@openzeppelin` dependency
* Default compiler settings for Solidity v0.8.20+

---

##  Setup and Run Commands

###  Build Project

```bash
forge build
```

###  Run Local Node

```bash
anvil
```

###  Deploy Contract Locally

```bash
forge script script/DeployPreorderTokens.s.sol \
--rpc-url http://127.0.0.1:8545 \
--private-key <anvil_private_key> \
--broadcast
```

###  Test All Functions

```bash
forge test -vv
```

###  Interact with Contract

**Buy Tokens:**

```bash
cast send <contract_address> "buyTokens()" \
--rpc-url http://127.0.0.1:8545 \
--private-key <buyer_key> \
--value 1ether
```

**Withdraw Funds (Owner):**

```bash
cast send <contract_address> "withdrawFunds()" \
--rpc-url http://127.0.0.1:8545 \
--private-key <owner_key>
```

**Check Buyer Balance:**

```bash
cast call <contract_address> "balanceOf(address)" <buyer_address> \
--rpc-url http://127.0.0.1:8545
```

---

##  Sample Output

```
PreorderTokens deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Rate: 1000 tokens per ETH

 Buyer sent 1 ETH - received 1000 PDT
 Owner successfully withdrew 1 ETH
 Contract balance = 0
```

---

##  End of Project

This project successfully demonstrates a **token presale system** using ERC20 standards, fund management via Ownable, and real-time token sales logic.

