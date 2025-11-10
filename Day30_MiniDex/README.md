# Day 30 - Mini DEX (Final Build)

This project implements a minimal Decentralized Exchange using a Factory-Pair architecture. It allows creating liquidity pools for any two ERC20 tokens, adding and removing liquidity, and swapping based on the constant product formula. The structure follows the AMM pattern used in major DEX protocols but simplified for learning and clarity.

## What was built

The project consists of three main contracts: a token contract for testing, a Pair contract that holds reserves and executes swaps, and a Factory contract that creates Pair instances and tracks them. All deployment and local testing were done using Foundry. Contract interaction tests were reproduced in Remix to provide clear outputs and confirm that the implementation works correctly outside the local environment.

---

# Source Code Explanation

## MockToken.sol

A simple ERC20 token used for testing. It inherits from OpenZeppelin’s ERC20 implementation. The constructor mints a fixed supply to the deployer. This token is used as token A and token B in the Pair.

Key functionalities:

* Standard balance transfers
* Approvals for the Pair contract
* Easy minting during deployment

## MiniDexPair.sol

This is the core liquidity pool. It stores two ERC20 tokens and maintains reserves. It follows the constant product formula for pricing.

Main operations:

* addLiquidity: takes equal-value tokens and mints LP shares
* removeLiquidity: burns LP shares and returns proportional token amounts
* swap: sends one token in and returns the other, updating reserves
* getAmountOut: calculates output amount based on reserves
* getReserves: returns current reserves for view operations

The contract uses ReentrancyGuard from OpenZeppelin to avoid reentrancy issues.

## MiniDexFactory.sol

This contract creates and registers Pair contracts. It ensures only unique pairs are created and keeps mapping structures for fast lookup.

Main operations:

* createPair: deploys a new MiniDexPair instance
* getPair: returns a pair address based on token A and token B
* allPairs: list of all created pairs
* onlyOwner functions for controlling public pool creation

---

# Supporting Files

## Foundry.toml

Defines compiler version, optimizer settings, and remappings. It ensures that the repository compiles consistently across systems. Remappings link imports such as openzeppelin-contracts and forge-std to the correct library paths.

## Foundry Commands Used

Commands executed during testing and building:

* forge build: compiles all contracts
* forge clean: resets cache and artifacts
* forge test: runs unit tests
* forge remappings: prints remapping configuration
* forge install: installs OpenZeppelin and forge-std
  These commands help maintain a clean and deterministic development environment.

---

# OpenZeppelin Usage

OpenZeppelin contracts were used for:

* ERC20 token base implementation
* ReentrancyGuard for safety during swaps
* Ownable for Factory admin operations

These libraries provide audited and secure foundations so that the DEX logic can rely on proven components instead of rewriting core token and access logic.

---

# Why the lib Folder Was Removed Before Upload

The lib folder contains external dependencies (OpenZeppelin, forge-std). These libraries are large and not required in the submission repository. They also increase upload size and cause unnecessary merge conflicts. Since the contracts rely only on import paths, the reviewer can install dependencies locally. Removing lib keeps the repository clean, lightweight, and aligns with previous days’ submission norms.

---

# Remix IDE Notes

VSCode with Foundry uses internal remappings. Remix does not support remappings directly. Because of this, the import paths must be replaced.

In VSCode:
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

In Remix:
import "[https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/token/ERC20/ERC20.sol](https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/token/ERC20/ERC20.sol)";

The same applies for ReentrancyGuard and Ownable. This ensures Remix fetches the contracts directly from GitHub and resolves all imports without depending on local libraries.

---

# Sample Output Explanation (Remix)

Deployment steps in Remix:

1. Deploy two instances of MockToken (TokenA and TokenB)
2. Deploy MiniDexFactory
3. Use Factory to create a pair using tokenA and tokenB
4. Approve the pair contract from both tokens
5. Add liquidity through addLiquidity
6. View reserves using getReserves
7. Execute swap and verify balance differences
8. Remove liquidity and check returned amounts

Observed behavior:

* addLiquidity updates reserveA and reserveB correctly
* swaps adjust the constant product and return proportional output
* removing liquidity returns tokens based on LP shares
* factory correctly lists and returns pair addresses

These outputs confirm that the MiniDEX implementation behaves as expected in an isolated execution environment.

---

# Summary

This final day delivers a functional AMM-based DEX with factory, pair, and token contracts. The project integrates OpenZeppelin for safety, Foundry for testing and development, and Remix for verification. The implementation closely reflects practical decentralized exchange logic and concludes the 30-day Solidity challenge with a complete and working protocol.

---

# End of the Project.
