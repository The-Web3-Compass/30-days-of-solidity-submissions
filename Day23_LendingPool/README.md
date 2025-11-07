# Day 23 – Advanced Lending Pool (ERC20 Borrowing + Liquidation)

This project implements an upgraded lending pool system where users deposit ETH as collateral and borrow an ERC20 stablecoin. The contract includes debt tracking, interest accumulation, safe borrowing limits, reentrancy protection, and liquidation logic. The goal was to build a simplified version of how DeFi lending platforms like Aave work.

---

## Project Overview 

The lending pool allows users to deposit ETH, borrow a mock stablecoin (mUSD), repay their debt, and become liquidated if their health factor falls below a safe threshold. Interest is added to the debt over time, and the pool uses safe ERC20 transfers and reentrancy guards for security.

---

# Code Explanation 

## src Files

### `AdvancedLendingPool.sol`

* Handles entire lending logic.
* Users deposit ETH as collateral and borrow mUSD.
* Tracks collateral, debt, timestamps, interest rates, and liquidations.
* Includes health factor calculation.
* Protects functions with `ReentrancyGuard`.

### `MockStableToken.sol`

* Simple ERC20 token used as the borrowing asset.
* Mints an initial supply for testing and lending pool funding.
* Follows OpenZeppelin ERC20 implementation for safety.

---

## test Files

### `AdvancedLendingPool.t.sol`

* Tests deposits, borrowing limits, repayments, interest growth, and liquidation.
* Includes prank addresses to simulate different users.
* Checks revert conditions like insufficient liquidity.
* Validates healthy and unhealthy positions.

---

## Supporting Files

### `.gitignore`

* Added to stop large folders from polluting the repo.
* Prevents tracking `lib/` and `out/` because they are auto-generated.

### `.github/workflows/test.yml`

* CI pipeline to run Foundry tests automatically in GitHub Actions.

### `foundry.toml`

* Configures import paths and source directory.
* Sets remappings for OpenZeppelin and Forge Standard Library.

---

# Foundry Commands 

```
forge init      // Initialize a new Foundry project  
forge build     // Compile all contracts  
forge test      // Run all tests  
forge test -vv  // Run tests with detailed logs  
forge install   // Install dependencies  

```
# Installing OpenZeppelin

To use the audited ERC20 and security libraries, install OpenZeppelin via Foundry:

```
forge install OpenZeppelin/openzeppelin-contracts
```


The library will be available under:
```
lib/openzeppelin-contracts/
```


It is excluded from version control using .gitignore, since dependencies should be installed per developer and never pushed to GitHub.

---

# Why We Used OpenZeppelin

OpenZeppelin provides industry-standard audited smart contract implementations.
We used:

* `ERC20.sol` – for a reliable token implementation
* `ReentrancyGuard.sol` – to block reentrancy attacks
* IERC20 interfaces – for consistent token interactions

These libraries help avoid high-risk custom logic.

---

# Why We Did NOT Upload the `lib` Folder

The `lib/` folder contains dependencies installed through Foundry.
Uploading it causes several issues:

1. Git recursively tries to track nested repos inside dependencies.
2. This creates broken submodule references.
3. It leads to commit failures and prevents pushing to GitHub.
4. It increases repo size unnecessarily.

To avoid this, the `lib/` folder is excluded via `.gitignore` and can always be restored locally with:

```
forge install
```

---

# Issues Faced 

During initial uploads, the `lib` folder from a different day (Day18) broke the repository by creating corrupted submodule references.
This caused all git operations (add, commit, pull, rebase, push) to fail.
The fix was to remove the corrupted folder, delete submodule traces, and clean the history.

---

# Sample Output 

The first borrow test failed due to insufficient tokens inside the LendingPool.
After minting tokens to the pool, the test suite succeeded.

The two screenshots included:

* `Day23_Test_Failure_NoLiquidity.png` – shows initial test failure.
* `Day23_Test_Success_AfterFundingPool.png` – shows all tests passing.

---

# Summary

This project introduced advanced lending mechanics using ERC20 tokens, liquidation procedures, interest calculations, and secure contract design principles. The implementation mirrors the core logic behind real-world lending protocols while keeping the system readable and beginner-friendly. The testing and debugging process was essential in understanding liquidity requirements and the importance of ignoring library folders in Git.

---

# End of the Project.
