# Day 1 - ClickCounter.sol

## Overview
This is my submission for Day 1 of 30 Days of Solidity: a simple ClickCounter contract built with Foundry.

## Contract Explanation

- The ClickCounter contract maintains a counter that can be incremented, decremented, or reset. Each action is logged using an event (Clicked) that records the user and the new counter value. It demonstrates state variables, functions, error handling (require), and event logging in Solidity.

## Test Explanation

- The test suite verifies core functionalities of the contract using Foundry:

- testIncrement() ensures the counter increases correctly.

- testDecrement() ensures the counter decreases with safety checks.

- testReset() ensures the counter resets back to zero.

## Features
- click() - Increment counter by 1
  
- unclick() - Decrement counter by 1 (with safety check using require)

- reset() - Reset counter to 0

-  getCount() - View current count

-  event Clicked(address user, uint256 newCount) - Logs user interaction on-chain

## Tests
- Increment test

- Decrement test

- Reset test

All tests passed successfully using Foundry.

## Commands Used

### Compile
```shell
forge init clickcounter
cd clickcounter

forge build
forge test -vvvv
```

## Github commands

```shell
git checkout -b day1-clickcounter
git add .
git commit -m
```

## Sample Output:
```shell
forge test -vvvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 3 tests for test/ClickCounter.t.sol:ClickCounterTest
[PASS] testDecrement() (gas: 22542)
[PASS] testIncrement() (gas: 30494)
[PASS] testReset() (gas: 22172)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 10.53ms (2.12ms CPU time)

Ran 1 test suite in 19.75ms (10.53ms CPU time): 
3 tests passed, 0 failed, 0 skipped (3 total tests)
```

- This project demonstrates a basic Solidity smart contract with event logging and unit testing using Foundry.

## End of the project.
