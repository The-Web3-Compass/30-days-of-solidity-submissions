# Day 18 - Decentralized Crop Insurance using Weather Oracle

## Project Overview

This project demonstrates how blockchain can interact with real-world data using **Chainlink oracles**.
The goal is to build a **decentralized crop insurance system** where farmers can automatically receive payouts if rainfall levels drop below a certain threshold during the growing season.

Since smart contracts cannot directly access external data, an **oracle** acts as a bridge between the blockchain and real-world APIs. Here, a **mock weather oracle** is used to simulate live weather data for demonstration.

---

## Components

### 1. Smart Contracts (src/)

* **WeatherOracleMock.sol**
  A mock contract that simulates an oracle by storing rainfall data. In a real-world application, this would be replaced by an actual Chainlink oracle fetching live data from APIs.

* **WeatherConsumer.sol**
  This contract retrieves the rainfall data from the oracle and stores it for use by other contracts like the insurance contract.

* **CropInsurance.sol**
  The main contract that allows farmers to buy insurance policies. It checks the rainfall data from `WeatherConsumer` and automatically triggers payouts if the rainfall is below a defined threshold.

---

## 2. Deployment Scripts (script/)

Each script is used to deploy and interact with different parts of the system using **Foundry**.

* **DeployOracle.s.sol**
  Deploys the WeatherOracleMock contract to the blockchain.

* **DeployConsumer.s.sol**
  Deploys the WeatherConsumer contract and links it to the oracle.

* **DeployCropInsurance.s.sol**
  Deploys the CropInsurance contract, connecting it to the WeatherConsumer contract.

These scripts automate the entire deployment process on the **Sepolia testnet** using environment variables for network and wallet configuration.

---

## 3. Environment Configuration (.env)

A `.env` file is used to securely store private environment variables required for deployment.

```
SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY"
PRIVATE_KEY="0xYOUR_PRIVATE_KEY"
ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
CHAIN_ID="11155111"
ORACLE_ADDRESS="0x76966Ef59eF39F90F75468679D6397b38F90C23e"
CONSUMER_ADDRESS="0x0999381A124c511D398E2661feAb426294F008A5"
```

### Explanation:

* **SEPOLIA_RPC_URL**: Alchemy endpoint used to connect to the Sepolia Ethereum test network.
* **PRIVATE_KEY**: Wallet private key (from MetaMask) for transaction signing.
* **ETHERSCAN_API_KEY**: Used for contract verification.
* **CHAIN_ID**: Chain ID for the Sepolia network (11155111).
* **ORACLE_ADDRESS & CONSUMER_ADDRESS**: Automatically filled after deployment of those contracts.

---

## 4. Foundry Configuration (foundry.toml)

The Foundry configuration file defines compiler version, libraries, RPC endpoints, and environment variables.

```
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.19"

[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}" }

[profile.default.env]
PRIVATE_KEY = "${PRIVATE_KEY}"
```

---

## 5. Foundry Commands Used

### Building the Contracts

```
forge build
```

### Running Scripts (Deployments)

```
forge script script/DeployOracle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
forge script script/DeployConsumer.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
forge script script/DeployCropInsurance.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Checking Contract Storage or Calls

```
cast call <contract_address> "functionName()(returnType)" --rpc-url $SEPOLIA_RPC_URL
cast send <contract_address> "functionName(params...)" --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```

### Example

```
cast call 0x5bFEE1462c3Cd89b25d3Af5dbB44dC7d66838d79 "weatherConsumer()(address)" --rpc-url $SEPOLIA_RPC_URL
```

---

## 6. Sample Outputs (Deployment Summary)

**Oracle Deployment**

```
Oracle deployed at: 0x76966Ef59eF39F90F75468679D6397b38F90C23e
```

**Consumer Deployment**

```
Consumer deployed at: 0x0999381A124c511D398E2661feAb426294F008A5
```

**Crop Insurance Deployment**

```
CropInsurance deployed at: 0x5bFEE1462c3Cd89b25d3Af5dbB44dC7d66838d79
```

These addresses correspond to the contracts deployed on the Sepolia testnet using Foundry and Alchemy.

---

## 7. Chainlink Oracle Explanation

**Chainlink** provides a decentralized network of oracles that allow smart contracts to securely access external data such as weather, prices, or APIs.
In this project:

* The **oracle** (mocked version) represents a Chainlink node.
* It provides off-chain weather data to the **WeatherConsumer** contract.
* This enables the **CropInsurance** contract to make automated decisions (like payouts) based on real-world data.

If integrated with a real Chainlink weather data feed, farmers could receive insurance compensation automatically based on verified rainfall metrics.

---

## 8. MetaMask, Alchemy, and Network Setup

### MetaMask

A wallet used to:

* Manage test ETH for Sepolia.
* Sign transactions during deployment.

### Alchemy

Alchemy provides an RPC endpoint that allows Foundry to connect to the Ethereum Sepolia testnet.
You can create a free project in Alchemy by:

1. Visiting [alchemy.com](https://www.alchemy.com)
2. Creating an account.
3. Creating a new app and selecting the **Ethereum Sepolia Network**.
4. Copying the **HTTP URL** as your `SEPOLIA_RPC_URL`.

---

## 9. Final Summary

This project successfully demonstrates how to:

* Integrate **mock weather oracles** with smart contracts.
* Deploy contracts using **Foundry** and **Alchemy RPC**.
* Use **MetaMask** for wallet management and testnet transactions.
* Automate payouts in a **decentralized crop insurance** system.

---

# End of the Project.
