# Day 28 – Decentralized Governance

This project implements a complete on-chain governance workflow using Foundry. The system includes an ERC20 governance token, proposal creation, weighted voting, timelock delay, and final execution. The contract allows token holders to participate in decentralized decision-making while enforcing quorum and execution delays.

## Project Overview

The governance system contains:

1. A governance token contract used for vote weight.
2. A governance contract handling proposals, voting, timelock, and execution.
3. Scripts for basic contract deployment.
4. Tests validating proposal creation, voting, timelock expiration, and final execution.
5. Output screenshots demonstrating deployments and transaction flows.

## What Was Implemented

### GovernanceToken.sol

A basic ERC20 token used as a governance token.
Holders receive voting power equal to their token balance.
Key points:

* Standard ERC20 implementation.
* Required for proposal voting weight.

### DecentralizedGovernance.sol

The main governance contract.
Key functionalities:

* Create proposals with a description, target contract address, and calldata.
* Token-weighted voting (for/against).
* Simple deposit requirement for proposal creation.
* Quorum check before passing a proposal.
* Timelock delay before execution.
* Final execution of proposal calls.

Important elements:

* `createProposal` stores proposal data.
* `vote` verifies token balance and records support.
* `finalize` checks quorum and marks the proposal passed.
* `execute` runs the proposal after timelock.
* `hasVoted` prevents duplicate voting.

### foundry.toml

Used to configure Foundry test and build settings.
Sets directories, Solidity version, and optimizer settings.

### .gitignore

Used to exclude unnecessary folders such as `out`, `cache`, and `lib` so the repository remains clean.

## Foundry Commands Used

* `forge init` – initialize the project
* `forge build` – compile all contracts
* `forge test -vvv` – run detailed tests
* `anvil` – local blockchain for interactive debugging
* Deployment and execution through Remix for visual clarity

## Expected Outputs

During testing and Remix execution:

* Proposal creation emits a ProposalCreated event.
* Voting updates vote weight based on token balance.
* Finalization shows whether quorum is met.
* Execution triggers the target contract call and updates state (Counter increments).
* Timelock prevents early execution.

All execution outputs and screenshots are included inside the `outputs` folder.

---
# End of the project.
