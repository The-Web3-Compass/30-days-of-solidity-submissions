# Day 5 of 30

Concepts

- modifier
- msg.sender for ownership
- Basic access control

Progression

- Introduces basic access control patterns.

Example Application

Build a contract that simulates a treasure chest controlled by an owner. The owner can add treasure, approve withdrawals for specific users, and even withdraw treasure themselves. Other users can attempt to withdraw, but only if the owner has given them an allowance and they haven't withdrawn before. The owner can also reset withdrawal statuses and transfer ownership of the treasure chest. This demonstrates how to create a contract with restricted access using a 'modifier' and `msg.sender`, similar to how only an admin can perform certain actions in a game or application.

[sepolia contract](https://sepolia.etherscan.io/address/0x79ca465291c6d57a9ef39e40179c185fdc86f577#code)
