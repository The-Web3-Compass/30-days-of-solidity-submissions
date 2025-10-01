## Overview
ClickCounter.sol is a simple Solidity smart contract that implements a digital click counter. Each time the `click()` function is called, the counter increments by one. The contract also allows decrementing and resetting the count, making it a great starting point for learning interactive smart contracts and state management in Solidity.

## Features
- Increment the counter (`click()`)
- Decrement the counter (`unclick()`) with safety check
- Reset the counter (`reset()`)
- Retrieve the current count (`getCount()`)
- Emits events for all state changes to allow easy tracking off-chain

## Contract Functions

| Function       | Type   | Description |
|----------------|--------|-------------|
| `getCount()`   | view   | Returns the current counter value |
| `click()`      | external | Increments the counter by 1 and emits `Clicked` event |
| `unclick()`    | external | Decrements the counter by 1 (cannot go below 0) and emits `Unclicked` event |
| `reset()`      | external | Resets the counter to 0 and emits `Reset` event |

## Events

| Event         | Parameters               | Description |
|---------------|--------------------------|-------------|
| `Clicked`     | `caller` (address), `newCount` (uint256) | Emitted when the counter is incremented |
| `Unclicked`   | `caller` (address), `newCount` (uint256) | Emitted when the counter is decremented |
| `Reset`       | `caller` (address)      | Emitted when the counter is reset |

## Solidity Version
- `^0.8.20`

## Usage
1. Deploy the contract on any EVM-compatible blockchain (like Ethereum, Polygon, or a local Hardhat/Remix environment).  
2. Call `click()` to increment the counter.  
3. Call `unclick()` to decrement it.  
4. Call `reset()` to set the counter back to zero.  
5. Call `getCount()` to read the current value.

## Learning Outcomes
- Understanding basic Solidity syntax  
- Using state variables (`uint256`)  
- Creating functions for modifying state  
- Emitting and handling events  
- Implementing basic safety checks  

