# Day 7 of 30

Concepts

- address
- token transfer
- payable for gas
- validation (require)

Progression

- Extends personal balance tracking by introducing two-way interactions — debt recording, repayments, and actual ETH movement using `transfer` and `call`.

Example Application

Build a simple IOU contract for a private group of friends. Each user can deposit ETH, track personal balances, log who owes who, and settle debts — all on-chain. You’ll learn how to accept real Ether using `payable`, transfer funds between addresses, and use nested mappings to represent relationships like 'Alice owes Bob'. This contract mirrors real-world borrowing and lending, and teaches you how to model those interactions in Solidity.

[sepolia contract](https://sepolia.etherscan.io/address/0x64bd038f78e70f74661333c1ca2b91d0f2f0ea4d#code)
