# Day 1 - ClickCounter.sol

## Overview
This is my submission for Day 1 of 30 Days of Solidity: a simple ClickCounter contract built with Foundry.

## Features
- `click()` → Increment counter by 1
- `unclick()` → Decrement counter by 1 (with safety check using require)
- `reset()` → Reset counter to 0
- `getCount()` → View current count
- `event Clicked(address user, uint256 newCount)` → Logs user interaction on-chain

## Tests
- Increment test
- Decrement test
- Reset test

All tests passed successfully using Foundry.

## Commands Used

### Compile
```bash
forge init clickcounter

cd clickcounter


forge build

forge test -vvvv
'''

### Github commands

git checkout -b day1-clickcounter
git add .
git commit -m "Day 1 - ClickCounter submission"
git push origin day1-clickcounter
