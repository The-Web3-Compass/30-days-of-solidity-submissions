# Week 1 — Solidity Fundamentals (Day 2)
## Challenge: SaveMyName.sol

**Author:** Nadiatus Salam  
**Contract file:** `SaveMyName.sol`

### Challenge Recap
This challenge focuses on storing and retrieving basic user data on the blockchain:

- State variables (`string`, `bool`)
- Storage vs Memory in function parameters
- Storing text (name/bio) and boolean flags
- Creating a simple profile system

The goal is to build a contract where users can save their name (e.g., 'Alice') and a short bio (e.g., 'I build dApps'), demonstrating how to persist data on-chain.

---

## Contract Overview

`SaveMyName` is a profile storage contract that allows users to:

- **Save/Update Profile**: Store a name and bio string.
- **Check Existence**: A boolean flag `hasProfile` indicates if a profile exists.
- **Retrieve Data**: Read the stored information.
- **Delete Profile**: Clear the stored data (resetting strings to empty and bool to false).

The contract uses events to log changes efficiently and custom errors for gas optimization.

---

## File Header (SPDX + Pragma)

### 1) SPDX License Identifier
```solidity
// SPDX-License-Identifier: MIT
```
- Standard open-source license identifier.

### 2) Compiler Version
```solidity
pragma solidity ^0.8.24;
```
- Targets Solidity version `0.8.24` or newer (within the 0.8.x range).

---

## State Variables

```solidity
string public name;
string public bio;
bool public hasProfile;
```

Key points:
- `string`: Used for dynamic text data. Storing strings on-chain is expensive, so keep them short!
- `bool`: A simple true/false flag. Here it tracks if a user has created a profile.
- `public`: Automatically generates getter functions for these variables.

---

## Events & Errors

### Events
```solidity
event ProfileUpdated(address indexed user, string newName, string newBio);
event ProfileDeleted(address indexed user);
```
- **Why?** Events allow off-chain apps (frontends) to listen for updates in real-time without constantly querying the blockchain.

### Custom Errors
```solidity
error ProfileNotFound();
```
- **Why?** Using custom errors (`revert ProfileNotFound()`) is much cheaper than `require(..., "String Message")` because it doesn't store long error strings on-chain.

---

## Functions (Behavior + Best Practices)

### 1) `saveProfile()`
```solidity
function saveProfile(string memory _name, string memory _bio) external {
    name = _name;
    bio = _bio;
    hasProfile = true;
    
    emit ProfileUpdated(msg.sender, _name, _bio);
}
```

Behavior:
- Updates `name` and `bio` state variables.
- Sets `hasProfile` to `true`.
- Emits `ProfileUpdated` event.

**Why `memory`?**
- Function parameters for reference types (like `string`, `array`, `struct`) must specify a data location.
- `memory` means the data is temporary during function execution (cheaper than `storage` or `calldata` in this context for inputs).

---

### 2) `getProfile()`
```solidity
function getProfile() external view returns (string memory _name, string memory _bio, bool _hasProfile) {
    return (name, bio, hasProfile);
}
```

Behavior:
- Returns all profile data in a single call.
- Useful for frontends to fetch everything at once.

---

### 3) `deleteProfile()`
```solidity
function deleteProfile() external {
    if (!hasProfile) revert ProfileNotFound();

    delete name;
    delete bio;
    hasProfile = false;

    emit ProfileDeleted(msg.sender);
}
```

Behavior:
- Checks if a profile exists; if not, reverts with `ProfileNotFound`.
- Uses the `delete` keyword to reset variables to their default values (empty string `""` for strings, `false` for bool).
- Emits `ProfileDeleted`.

**Gas Optimization**:
- Deleting storage slots (resetting non-zero values to zero) refunds some gas (up to a limit), incentivizing users to clean up unused state.

---

## “Fundamentals” Checklist (What You Practiced)

`string` data type for text  
`bool` data type for flags  
`memory` vs `storage` concepts (in function args)  
Persisting data on-chain  
Deleting/Resetting state variables  
Events for off-chain tracking  
Custom Errors for gas efficiency  

---

## How To Test (Remix Quick Guide)

1. Open Remix: https://remix.ethereum.org  
2. Create `SaveMyName.sol` and paste the contract code.
3. **Compile** with version `0.8.24`.
4. **Deploy** to Remix VM.
5. **Interact**:
   - Call `getProfile` → returns empty strings and `false`.
   - Call `saveProfile("Alice", "I love Solidity")` → successful transaction.
   - Call `getProfile` again → returns "Alice", "I love Solidity", `true`.
   - Call `deleteProfile` → resets everything.
   - Call `deleteProfile` again → reverts with `ProfileNotFound` error.