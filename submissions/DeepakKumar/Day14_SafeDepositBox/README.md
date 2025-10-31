---

# Day 14 - SafeDepositBox.sol

### Task Objective

To build a modular smart contract system that represents a digital safe deposit box bank, supporting multiple types of deposit boxes with ownership transfer and secure contract-to-contract communication.

---

### Concepts Covered

* Interfaces
* Abstraction
* Ownership Transfer
* Contract-to-Contract Interaction

---

### Description

The goal of this task is to design a smart bank that allows users to create and interact with various deposit boxes such as basic, premium, and time-locked versions. Each deposit box implements a standard interface for unified interaction and ownership management.
A central `VaultManager` contract facilitates the registration of deposit boxes and manages ownership transfers between users securely, similar to handing over digital locker keys.

This exercise focuses on understanding interface-based architecture, modular contract design, and safe inter-contract communication.

---

---

### Pre-installation

Ensure Foundry is installed and up to date.

```
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

### Commands Used

**Build Contracts**

```
forge build
```

**Run Tests**

```
forge test -vvvv
```

**Run Local Deployment**
Start Anvil in a new terminal:

```
anvil
```

Then execute deployment:

```
forge script script/Deploy.s.sol --fork-url http://127.0.0.1:8545 --sender <your-anvil-address> --private-key <your-anvil-private-key> --broadcast
```

---

### Explanation of Contracts

**IDepositBox.sol**
Defines the common interface used by all deposit boxes, ensuring standardized functions for deposit, withdrawal, ownership transfer, and balance checks.

**BasicDepositBox.sol**
Implements a simple deposit box where the owner can deposit and withdraw ETH, and transfer ownership.

**PremiumDepositBox.sol**
Extends functionality with higher withdrawal limits and a minimum deposit requirement.

**TimeLockedDepositBox.sol**
Implements a time-based lock mechanism, restricting withdrawals until a set unlock period has passed.

**VaultManager.sol**
Acts as a registry and manager for all deposit boxes. It handles vault ownership transfers and provides a centralized interaction point between users and deposit boxes.

---

### Test Explanation

**SafeDepositBoxTest.t.sol**
A Foundry test script verifying core functionalities including deposits, withdrawals, and ownership transfers between users. Ensures each deposit box type adheres to the defined interface and behaves consistently.

---

### Learning Outcome

* Implemented modular smart contract design using interfaces and abstraction.
* Understood ownership transfer logic and secure access control.
* Practiced inter-contract communication patterns safely using standard interfaces.
* Developed confidence in structuring multi-contract Solidity systems.

---

# End of the Project.
