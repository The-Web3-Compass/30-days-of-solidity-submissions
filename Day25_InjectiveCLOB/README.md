# Day 25 - Injective CLOB Demo

This project demonstrates how to interact with the Injective Chain's Central Limit Order Book (CLOB) using Solidity through the Injective precompile. The goal was to build a minimal contract that places and cancels orders by calling the on-chain CLOB module.

The task focuses on real-world DeFi applications, showing how to use Injective’s low-level precompile interface instead of AMM-style logic.

---

## Project Explanation

The contract interacts with the CLOB precompile address and performs two operations:

1. Placing an order
2. Cancelling an existing order

The precompile exposes functionality similar to an exchange order book, allowing a contract to place limit orders directly on Injective’s trading engine.

Foundry was used to build and test the contract locally. Since CLOB precompiles do not work inside local EVM tests, we used a simple deployment and event-emission test to validate compilation and contract structure.

All unnecessary folders such as lib, out, cache, and broadcast were removed to keep the repository clean.

---

## Source Code Description

### `ICLOBModule.sol`

Defines the interface for interacting with the Injective CLOB precompile.
Includes functions:

* `placeOrder`
* `cancelOrder`

Each returns the order ID or cancel status.

### `InjectiveClobDemo.sol`

Main contract for the task.

Key components:

* Constant reference to the precompile address
* A function to place an order by calling `CLOB.placeOrder(...)`
* A function to cancel an order by calling `CLOB.cancelOrder(...)`
* Events to log order placement and cancellation

This provides a minimal functional wrapper around the Injective CLOB module.

---

## Test File Explanation

### `InjectiveClobDemo.t.sol`

Contains two basic tests:

* `testDeploy()`
  Confirms that the contract deploys successfully.

* `testPlaceAndCancelEventsOnLocal()`
  Tests that calling `place()` and `cancel()` trigger the correct events.
  (Since precompile execution is not available in local EVM, this test focuses on event emission and call structure.)

This verifies contract behavior without expecting live Injective responses.

---

## Foundry Commands

```
forge init
forge build
forge test -vv
forge install foundry-rs/forge-std --no-commit
```

These were used during compilation, testing, and setting up the project.

---

## Foundry.toml

Contains basic project configuration:

* Solidity version
* Output directories
* Remapping for Forge Standard Library

It ensures the build system resolves imports correctly.

---

## Why the `lib` Folder Was Not Uploaded

The `lib` directory contains dependencies installed by Foundry and often contains thousands of files. Uploading it previously caused Git corruption issues. Because of that, `.gitignore` excludes:

* lib
* out
* cache
* broadcast

This keeps the repository clean and avoids errors.

---

## Sample Test Output (Expected)

Running the tests locally should display:

* Contract deploy success
* Event emitted properly for order placement
* Event emitted properly for cancellation

Compile and test sequences show successful execution with no precompile failures in local mode.

---

## Summary

This task demonstrates how external modules on Injective can be accessed directly through Solidity using precompile addresses.
Created a simple order-placing contract, wrote basic tests for deploy and event behavior, cleaned the project, and ensured it compiles correctly in Foundry. 

# End of the Project.
