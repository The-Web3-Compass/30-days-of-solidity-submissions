# Day 20 – FortKnox

## Project Overview

The **FortKnox** challenge focuses on understanding and preventing **reentrancy attacks** in Solidity smart contracts.
This exercise demonstrates both a **vulnerable implementation** and a **secure version** using proper state-update patterns and reentrancy guards.

---

## Objective

The goal of this project is to simulate a vault system where users can deposit and withdraw funds.
It highlights how a malicious contract can repeatedly call back into a function before the previous execution completes,
and how to fix the issue by following the **checks-effects-interactions** pattern or using **OpenZeppelin’s ReentrancyGuard**.

---

## File explanation:
### src/GoldVault.sol

- A simple vault contract that allows deposits and withdrawals of Ether.
- The first version contains a reentrancy vulnerability because it transfers Ether before updating the user’s balance.
- The fixed version updates balances before external calls, following the checks-effects-interactions pattern to prevent reentrancy.

src/GoldThief.sol

- A malicious contract used to exploit the vulnerable GoldVault.
- It calls the vault’s withdraw function repeatedly in a single transaction using the fallback function,
demonstrating how reentrancy drains funds before the vault can update user balances.

test/FortKnox.t.sol

Contains Foundry-based test cases for both the vulnerable and secure versions of GoldVault.

The tests include:

- Deploying both contracts
- Depositing funds into the vault
- Simulating an attack from GoldThief
- Verifying that the vulnerable contract loses funds
- Confirming that the fixed contract resists the attack

---


## Test Execution

Build the project:

```bash
forge build
```

Run all tests:

```bash
forge test -vv
```

The test suite verifies:

* The attacker successfully drains funds from the vulnerable contract.
* The secure version of the contract resists reentrancy attempts.

---

## Sample Output

The following images show the build and test results generated using Foundry:

* **forge_build_success.png** – successful compilation of all contracts.
* **forge_test_vulnerable_safe.png** – test results comparing the vulnerable and protected cases.
(Check inside images)
---

## Key Concepts Learned

* Reentrancy vulnerabilities in Ethereum contracts.
* Importance of updating state before external calls.
* Using `ReentrancyGuard` and the checks-effects-interactions pattern.
* Writing targeted tests for security validation in Foundry.

---

## Summary

The FortKnox exercise demonstrates how small design oversights can lead to major vulnerabilities in smart contracts.
By implementing the correct order of operations and using simple defensive programming techniques,
reentrancy attacks can be fully prevented, ensuring safer fund management on the blockchain.

---

# End of the Project. 
