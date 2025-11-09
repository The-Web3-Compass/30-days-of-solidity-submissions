# Day 25 - Automated Market Maker (AMM)

## Overview of the Task

The objective of Day 25 was to build a simple Automated Market Maker (AMM) similar to Uniswap V1. The system should allow:

1. Deployment of two ERC20 tokens (TokenA and TokenB).
2. Deployment of an LP Token representing liquidity shares.
3. Adding liquidity to the AMM pool.
4. Approval of token transfers.
5. Verification of successful AMM deployment and liquidity addition.
6. Automation of the above steps using Foundry scripts.

This challenge required understanding of ERC20 tokens, liquidity pools, constant-product AMM logic, token approvals, and Foundry scripting.

---

## What was Implemented

1. **TokenA.sol and TokenB.sol**
   Two simple ERC20 tokens based on OpenZeppelin ERC20.

2. **AutomatedMarketMaker.sol**
   The AMM contract responsible for:

   * Storing reserves of TokenA and TokenB
   * Minting LP tokens to liquidity providers
   * Handling addLiquidity logic

3. **DeployAMM.s.sol**
   A Foundry script that:

   * Deploys TokenA, TokenB, and AMM
   * Approves tokens for AMM
   * Adds liquidity to the pool
   * Produces broadcast and output files


4. **Foundry.toml** configured for the day’s project, including remappings for OpenZeppelin and forge-std.

5. **.gitignore** updated to prevent inclusion of heavy or unnecessary folders (lib, cache, out).

---

# Explanation of Source Code 

## TokenA.sol and TokenB.sol

Both tokens follow the same structure:

* Import OpenZeppelin’s ERC20 contract.
* Constructor mints initial supply to the deployer.
* Standard decimals, transfer, approve, and allowance logic are inherited.

These tokens are used as the underlying assets of the AMM pool.

## AutomatedMarketMaker.sol

This contract implements simplified AMM logic.

Key features:

1. **State Variables**

   * tokenA and tokenB addresses
   * lpToken address
   * reserves for both tokens

2. **Constructor**

   * Initializes the tokens
   * Deploys an LP token

3. **addLiquidity**

   * Requires both token amounts > 0
   * Transfers tokens from the liquidity provider
   * Mints LP tokens proportional to liquidity added
   * Updates reserves
   * Used in this project to load initial liquidity into the pool

The contract does not implement swaps here; the task focuses solely on liquidity provision.

---

# Explanation of Script Files

## DeployAMM.s.sol

The primary automation script.

Execution steps:

1. Starts broadcast with the deployer's private key.
2. Deploys:

   * TokenA
   * TokenB
   * AMM contract
3. Approves AMM to spend tokens.
4. Calls addLiquidity with predetermined amounts.
5. Stops broadcast and prints deployed addresses.

This script ensures complete reproducibility of the AMM setup.

---

# Foundry Commands Used

1. **Install OpenZeppelin**

```
forge install OpenZeppelin/openzeppelin-contracts
```

2. **Compile**

```
forge build
```

3. **Script Deployment**

```
forge script script/DeployAMM.s.sol
```

4. **Script with Broadcasting**

```
forge script script/DeployAMM.s.sol --rpc-url $RPC_URL --private-key $PK --broadcast
```

5. **Cast Token Approvals**

```
cast send <tokenAddress> "approve(address,uint256)" <AMM> <amount> --rpc-url $RPC_URL --private-key $PK
```

6. **Add Liquidity**

```
cast send <AMM_address> "addLiquidity(uint256,uint256)" <amountA> <amountB> --rpc-url $RPC_URL --private-key $PK
```


# Explanation of foundry.toml

The foundry.toml file configures project-wide settings such as:

* Solidity version
* Optimizer settings
* Remappings for imports
* Directories for src, script, test
* Compatible formatting tools

In this project:

* Remapping to OpenZeppelin and forge-std is essential to import ERC20 and scripting utilities.
* Without proper configuration, imports fail and compilation breaks.

---

# Purpose of .gitignore

The .gitignore file prevents heavy or unnecessary files from being committed to GitHub.

Folders excluded:

* lib/
* cache/
* out/
* broadcast/ dry-run logs
* node_modules/

Reason:

* lib contains thousands of OpenZeppelin files
* out and cache contain compiled artifacts
* broadcast can contain sensitive deployment information
* These files are not needed in the repository

---

# If OpenZeppelin lib is uploaded, what GitHub issues occur?

Uploading the OpenZeppelin library causes several serious problems:

1. **Repository Size Explosion**
   The lib folder contains more than 800 files.
   GitHub marks the repository as heavy and affects cloning speed.

2. **Submodule Conflicts**
   Git thinks the lib folder is a submodule.
   This creates persistent merge conflicts and prevents normal git push or pull.

3. **Pull Errors**
   GitHub will reject pushes with errors like:

   * updates were rejected
   * merge conflicts in .gitmodules
   * unmerged paths
   * cannot remove submodule

4. **Corrupted Project Structure**
   VSCode and Foundry will treat it like an overridden dependency folder.

5. **Repeated Git Breakage**
   Every push, pull, or rebase becomes extremely difficult.

For these reasons, lib must always be added to .gitignore.

---

# Summary

Day 25 covered a complete end-to-end workflow:

* Creating ERC20 tokens
* Deploying a custom AMM contract
* Providing liquidity
* Running Foundry scripts
* Fixing deployment and git issues
* Generating structured outputs
* Ensuring a clean repository with proper .gitignore

The project successfully demonstrates essential AMM concepts and the ability to automate deployment using Foundry.

---

# End of the project.
