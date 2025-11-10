# Day 29 - Simple Stablecoin

This project implements a basic over-collateralized stablecoin system. The goal was to understand how stablecoins maintain value using collateral, price feeds, and mint/redeem functions. The project was built and tested using Foundry, with a local mock price feed and mock ERC20 token.

## What I Did

I created a minimal stablecoin contract that allows users to mint stablecoins by depositing collateral, and redeem stablecoins back into collateral based on a mock Chainlink price. I deployed the mock token, the mock price feed, and the stablecoin contract using Foundry scripts. I tested the core functions on Remix using injected Web3.

## Project Structure

### 1. MockToken.sol

Simple ERC20 token used as collateral for minting the stablecoin. Includes mint functionality for testing.

### 2. MockV3Aggregator.sol

Lightweight Chainlink-style price feed returning a fixed answer. Used to simulate a collateral asset price.

### 3. SimpleStablecoin.sol

Main contract that handles minting and redeeming. Tracks user balances and uses the price feed for collateral valuation.

### 4. Deploy.s.sol

Script that deploys MockToken, MockV3Aggregator, and SimpleStablecoin. Helps automate deployment for testing.


## Foundry Commands Used

forge init – created project structure
forge build – compiled all contracts
forge remappings – configured openzeppelin and forge-std
forge clean – removed cache
forge script Deploy.s.sol – simulated deployment


## Outputs

Contract deployment screenshots and execution outputs (mint, approve, redeem) are stored inside the outputs folder.


## Why lib Folder Was Removed

The lib folder contains forge-std and openzeppelin libraries. They must not be uploaded in official submissions because they increase size, create submodule issues, and are auto-installed during build. A caution note is added here to avoid adding lib, cache, out, and broadcast directories.


## Summary

This task covered creating a simple stablecoin with collateralization logic, integrating a mock price feed, testing mint/redeem, and deploying using Foundry. It introduced how stablecoins maintain value and how collateral ratios influence minting capacity.

# End of the Project.

