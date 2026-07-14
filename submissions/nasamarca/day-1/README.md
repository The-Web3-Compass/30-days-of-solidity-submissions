# Week 1 — Solidity Fundamentals (Day 1)
## Challenge: ClickCounter.sol

**Author:** Nadiatus Salam  
**Contract file:** `ClickCounter.sol`

### Challenge Recap
This challenge focuses on the absolute fundamentals of writing interactive smart contracts:

- Basic Solidity syntax
- State variables (`uint` / `uint256`)
- Increment / decrement functions
- Storing and modifying data on-chain via function calls

The goal is to build a simple “digital clicker”: each time `click()` is called, a stored number increases by 1.

---

## Contract Overview

`ClickCounter` is a minimal stateful contract that stores a single number (`counter`) and provides functions to:

- Increment the counter (`click()`)
- Decrement the counter safely (`decrement()`)
- Reset the counter to zero (`reset()`)
- Read the current value (`counter` public getter)

The contract also emits events whenever state changes, so off-chain apps (frontends, indexers) can track activity without constantly polling.

---

## File Header (SPDX + Pragma)

### 1) SPDX License Identifier
```solidity
// SPDX-License-Identifier: MIT
```
- This indicates the license for the source code.
- Many toolchains warn if SPDX is missing.

### 2) Compiler Version
```solidity
pragma solidity ^0.8.24;
```
- This means the contract is intended for Solidity `0.8.24` and compatible versions up to (but not including) `0.9.0`.
- Solidity `0.8.x` has built-in overflow/underflow checks by default, which improves safety.

---

## NatSpec Documentation
At the top of the contract and above each function, the code uses NatSpec (`/** ... */`) to document:
- What the contract/function does (`@notice`)
- Extra dev notes (`@dev`)
- Ownership / attribution (`@author`)

This is useful for readability and for generating documentation.

---

## State Variable

```solidity
uint256 public counter;
```

Key points:
- `uint256` is an unsigned integer (cannot be negative).
- `public` automatically creates a getter function:
  - You can call `counter()` externally to read the value.
- Because `counter` is a *state variable*, changing it costs gas.

---

## Events

```solidity
event Clicked(address indexed caller, uint256 newCounter);
event Decremented(address indexed caller, uint256 newCounter);
event Reset(address indexed caller);
```

Why events matter:
- They are written to transaction logs (cheaper than storing extra state).
- Off-chain apps can subscribe to events to update UI/state efficiently.
- `indexed caller` makes it easy to filter logs by address.

When events are emitted:
- `Clicked` after successful `click()`
- `Decremented` after successful `decrement()`
- `Reset` after `reset()`

---

## Functions (Behavior + Best Practices)

### 1) `click()`
```solidity
function click() external {
    unchecked {
        counter++;
    }
    emit Clicked(msg.sender, counter);
}
```

Behavior:
- Increments `counter` by 1.
- Emits `Clicked(caller, newCounter)`.

Notes:
- `external` is slightly more optimal than `public` for functions that are meant to be called from outside the contract.
- `unchecked { counter++; }` is used because overflowing a `uint256` is practically impossible, saving gas by skipping overflow checks.

---

### 2) `decrement()`
```solidity
function decrement() external {
    if (counter == 0) revert CounterIsZero();
    unchecked {
        counter--;
    }
    emit Decremented(msg.sender, counter);
}
```

Behavior:
- Decreases `counter` by 1.
- If `counter` is already 0, the function reverts with custom error:
  - `error CounterIsZero()`

Why Custom Error?
- `revert CounterIsZero()` is much cheaper (gas-wise) than `require(..., "string message")`.

Why `unchecked`?
- In Solidity `0.8+`, arithmetic is checked by default (adds extra gas).
- After the check `if (counter == 0)`, underflow is impossible, so we can safely use `unchecked` to save gas.

---

### 3) `reset()`
```solidity
function reset() external {
    counter = 0;
    emit Reset(msg.sender);
}
```

Behavior:
- Resets `counter` to zero.
- Emits `Reset(caller)`.

Note:
- This is a direct write to storage (costs gas).
- Useful for demonstrating state changes.

---

### 4) Gas Optimizations Added
- **Custom Errors**: Replaced `require` string messages with `error CounterIsZero()` to save deployment and execution gas.
- **Unchecked Math**: Used `unchecked { ... }` where overflow/underflow is impossible or checked manually.
- **Removed Redundant Getter**: Removed `getCounter()` since `public` variable `counter` already provides a free getter.

---

## “Fundamentals” Checklist (What You Practiced)

Basic Solidity syntax  
Declaring a contract and state variable  
Using `uint256` (unsigned integer)  
Writing external functions that modify state  
Increment/decrement logic  
Using `require` for validation  
Using `view` for read-only functions  
Emitting events for off-chain visibility  
NatSpec for documentation

---

## How To Test (Remix Quick Guide)

1. Open Remix: https://remix.ethereum.org  
2. Create `ClickCounter.sol` and paste the contract code.
3. Go to **Solidity Compiler**
   - Set compiler version to `0.8.24`
   - Click **Compile**
4. Go to **Deploy & Run Transactions**
   - Environment: **Remix VM (Cancun)**
   - Click **Deploy**
5. Interact with the deployed contract:
   - Call `counter` → should return `0`
   - Call `click` → counter becomes `1`
   - Call `click` again → counter becomes `2`
   - Call `decrement` → counter becomes `1`
   - Call `reset` → counter becomes `0`
   - Call `decrement` while counter is `0` → should revert with `CounterIsZero` error
6. Check Remix terminal/logs to see emitted events (`Clicked`, `Decremented`, `Reset`).

---

## Notes / Possible Improvements (Optional, Beyond Day 1)
These are not required for the challenge, but good to know:
- Add a constructor to set an initial counter value.
- Add access control so only an owner can `reset()`.
- Remove `getCounter()` to keep the contract minimal (since `counter` is already public).