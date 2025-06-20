# Day 20 of 30

Concepts

- Reentrancy attacks
- nonReentrant modifier
- security best practices

Progression

- Introduces critical security concepts.

Example Application

Build a secure digital vault where users can deposit and withdraw tokenized gold (or any valuable asset), ensuring it's protected from reentrancy attacks. Imagine you're creating a decentralized version of Fort Knox — users lock up tokenized gold, and can later withdraw it. But just like a real vault, this contract must prevent attackers from repeatedly triggering the withdrawal logic before the balance updates. You'll implement the `nonReentrant` modifier to block reentry attempts, and follow Solidity security best practices to lock down your contract. This project shows how a seemingly simple withdrawal function can become a vulnerability — and how to defend it properly.

[FortKnox sepolia Contract](https://sepolia.etherscan.io/address/0xa84d4fdd059e9405721f9ca0a12475fdccd85a31#code)

[Day 12](../day12/README.md)
[MyToken sepolia Contract](https://sepolia.etherscan.io/address/0x612F1bd01228DDe741a77532f0591F8B3843460C#code)

---

## testing

- deploy using day12 token `0x612F1bd01228DDe741a77532f0591F8B3843460C`: [contract](https://sepolia.etherscan.io/address/0x544acc6b63e29ab125c1f769188ec0dca42797c0)
