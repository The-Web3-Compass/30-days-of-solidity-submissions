# Day 11 of 30

Concepts

- Ownable pattern
- inheritance
- robust access control

Progression

- Builds on basic ownership with a modular, inheritance-based access control pattern.

Example Application

Build a secure Vault contract that only the owner (master key holder) can control. You'll split your logic into two parts: a reusable 'Ownable' base contract and a 'VaultMaster' contract that inherits from it. Only the owner can withdraw funds or transfer ownership. This shows how to use Solidity's inheritance model to write clean, reusable access control patterns — just like in real-world production contracts. It's like building a secure digital safe where only the master key holder can access or delegate control.

[sepolia Contract](https://sepolia.etherscan.io/address/0x84652ED5B621739d9E416C13074041e2e6c06DB3#code)
