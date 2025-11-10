# Day 27 - Yield Farming Contract

This task implements a complete Yield Farming system using Solidity. The goal was to create a staking and rewards mechanism where users can deposit a token, accumulate rewards over time, and later withdraw both their stake and earned rewards. This project was built in Foundry for the official submission, and the same logic was also tested on Remix using two custom ERC20 tokens.

## What was Built 

Created two ERC20 tokens using a SimpleToken contract: one token acts as the staking token and the other as the reward token. We then deployed a YieldFarming contract that handles staking, unstaking, updating user reward data, distributing rewards, and allowing the owner to refill the reward pool. All core staking logic is implemented with a reward-per-second model.

The project includes a Foundry project structure, source files, gitignore configuration, screenshots, and a separate workflow file.

## SimpleToken

SimpleToken is a basic ERC20 token used for both the staking and reward tokens. It uses OpenZeppelin’s ERC20 implementation and mints an initial supply to the deployer. This contract was used to create StakeToken and RewardToken during Remix testing.

## YieldFarming Contract

The YieldFarming contract manages user staking and reward calculations. It stores user stake information, updates rewards based on time passed, and ensures correct transfer of tokens. The contract uses ReentrancyGuard for safety and allows the owner to refill the reward pool. Key actions include stake, unstake, claimRewards, pendingRewards, and emergencyWithdraw.

## Foundry Commands Used
```
forge init
forge install OpenZeppelin/openzeppelin-contracts
forge build
forge test

```
These commands set up the project, installed dependencies, compiled the contracts, and ensured everything worked correctly.

## Foundry.toml

The Foundry.toml file defines the remappings required for OpenZeppelin libraries, the source and output directories, and the Solidity version used. It ensures the project compiles correctly without needing Remix URL imports.

## Gitignore

The gitignore file excludes the lib, out, cache, and broadcast folders. This prevents unnecessary dependencies, artifacts, and heavy folders from being pushed to GitHub, keeping the submission clean. The lib folder caused issues before, so it was specifically excluded.

## Outputs and Testing

Screenshots were captured from Remix to demonstrate the following steps:

```
Deploying the staking token
Deploying the reward token
Deploying the YieldFarming contract
Approving tokens
Staking tokens
Checking user stake data
Checking pending rewards
Refilling the reward pool
Claiming rewards
Unstaking tokens

```

These images were added inside the outputs folder as evidence of correct execution.

## Summary

Day 27 introduced a complete yield farming system with staking, reward tracking, and safe withdrawal mechanisms. The project included ERC20 token creation, reward distribution logic, testing in Remix, and a clean Foundry setup for submission. All required files were prepared without the lib folder and submitted in a separate directory to avoid conflicts.

---

# End of The project.

