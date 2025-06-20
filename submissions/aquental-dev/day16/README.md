# Day 16 of 30

Concepts

- delegatecall
- code execution context
- libraries

Progression

- Introduces advanced execution control.

Example Application

Build a modular profile system for a Web3 game. The core contract stores each player's basic profile (like name and avatar), but players can activate optional 'plugins' to add extra features like achievements, inventory management, battle stats, or social interactions. Each plugin is a separate contract with its own logic, and the main contract uses `delegatecall` to execute plugin functions while keeping all data in the core profile. This allows developers to add or upgrade features without redeploying the main contract—just like installing new add-ons in a game. You'll learn how to use `delegatecall` safely, manage execution context, and organize external logic in a modular way.

[PluginStore sepolia Contract](https://sepolia.etherscan.io/address/0x2a48982e80e7d9cfd1e4934e374215edb212ae61#code)
[AchievementPlugin sepolia Contract](0xd9dB9Bde1e7534D04c0Ea8F24c8DAffD61F32E41)
