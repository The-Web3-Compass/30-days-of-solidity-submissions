# Day 15 - GasSaver.sol

## Objective
To build a gas-optimized voting smart contract focusing on efficient storage management, calldata usage, and minimizing state changes. The goal is to understand how to write Solidity contracts that consume less gas without losing accuracy or functionality.

## Concepts Covered
- Gas optimization
- Efficient data locations
- Minimizing storage writes
- Calldata vs memory usage

## Explanation
In this task, a simple voting system is created where users can add proposals and cast votes. The challenge focuses on reducing gas costs by avoiding unnecessary storage writes, using storage references effectively, and implementing loops with unchecked increments to save gas.

The contract uses a struct `Proposal` that stores a proposal's name and vote count. Mappings are used to track addresses that have already voted. The `addProposal` function allows adding new proposals one by one instead of handling memory arrays, which simplifies operations and saves gas.

Functions are designed with gas efficiency in mind:
- `addProposal` adds proposals directly into storage.
- `vote` restricts double voting and minimizes storage reads/writes.
- `winningProposal` loops through proposals efficiently to determine the winner.

## Files Included
1. `src/GasSaver.sol` - Main contract containing logic for adding proposals, voting, and determining the winner.
2. `test/GasSaver.t.sol` - Test cases for validating voting functionality and restrictions.
3. `foundry.toml` - Foundry configuration file.
4. `.gas-snapshot` - Gas usage report generated using Foundry.
5. `README.md` - Documentation for the task.

## Foundry Commands Used
```
forge build
forge test
forge snapshot
```

## Output Summary
All test cases passed successfully.

```
Ran 3 tests for test/GasSaver.t.sol:GasSaverTest
[PASS] testCannotVoteTwice() (gas: 57477)
[PASS] testVoteOnce() (gas: 62230)
[PASS] testWinningProposal() (gas: 64148)
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

## Learning Outcome
- Understood how calldata, memory, and storage affect gas consumption.
- Learned to optimize loops using unchecked blocks.
- Gained experience in reducing storage operations to save gas.
- Developed a better understanding of writing performance-optimized Solidity contracts.

# End of the Project.
