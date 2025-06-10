# Day 10 of 30

Concepts

- Events
- logging data
- Indexed parameters
- emitting events

Progression

- Introduces event logging for debugging and tracking.

Example Application

Create a smart contract that logs user workouts and emits events when fitness goals are reached — like 10 workouts in a week or 500 total minutes. Users log each session (type, duration, calories), and the contract tracks progress. Events use _indexed_ parameters to make it easy for frontends or off-chain tools to filter logs by user and milestone — just like a backend for a decentralized fitness tracker with achievement unlocks.

[sepolia Contract](https://sepolia.etherscan.io/address/0xb6266536a7be8ebf06f6616cd10a03fafd2cbea7#code)
