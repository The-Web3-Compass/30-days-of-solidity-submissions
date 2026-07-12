# Smart Bank - SafeDepositBox System

A comprehensive smart contract system that implements a modular smart bank with different types of deposit boxes. Users can store secrets and ETH in digital lockers with varying features, and transfer ownership like handing over a physical key.

## 🎯 Overview

This project demonstrates advanced Solidity concepts through a real-world use case - a smart bank system where users can rent digital deposit boxes with different features. The system uses interfaces, abstraction, and modular design to create a flexible and extensible architecture.

## 📋 Concepts Covered

### 1. **Interfaces** (`IDepositBox.sol`)
- Defines a common contract interface that all deposit boxes must implement
- Ensures consistency across different box types
- Enables polymorphism in contract-to-contract interactions
- Makes the system extensible for future box types

### 2. **Abstraction** (`BaseDepositBox.sol`)
- Abstract base contract providing common functionality
- Implements shared logic for all deposit box types
- Uses the `abstract` keyword and `virtual` functions
- Demonstrates the DRY (Don't Repeat Yourself) principle

### 3. **Ownership Transfer**
- Each deposit box has an owner who controls access
- Ownership can be transferred like passing a physical key
- Uses modifiers to restrict function access
- Emits events for transparency

### 4. **Contract-to-Contract Interaction** (`VaultManager.sol`)
- Central manager contract that deploys and interacts with deposit boxes
- Demonstrates calling functions on other contracts via interfaces
- Shows how to send ETH between contracts
- Implements tracking and management of multiple contract instances

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    VaultManager                          │
│  (Central hub for all deposit box interactions)         │
└───────────────────┬─────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌──────────────┐        ┌─────────────┐
│ IDepositBox  │◄───────│BaseDepositBox│
│  (Interface) │        │  (Abstract)  │
└──────────────┘        └──────┬───────┘
                               │
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
        ┌──────────────┐ ┌──────────┐ ┌─────────────┐
        │ BasicDepositBox│ │ PremiumBox│ │TimeLockedBox│
        └──────────────┘ └──────────┘ └─────────────┘
```

## 📁 Contract Files

### Core Contracts

1. **IDepositBox.sol** - Interface defining the contract for all deposit boxes
2. **BaseDepositBox.sol** - Abstract base class with shared functionality
3. **BasicDepositBox.sol** - Simple deposit box with standard features
4. **PremiumDepositBox.sol** - Enhanced box with minimum balance and daily withdrawal limits
5. **TimeLockedDepositBox.sol** - Box where funds are locked for a specified duration
6. **SafeDepositBox.sol** (VaultManager) - Central manager for all deposit boxes

## 🔑 Key Features

### All Deposit Boxes Support:
- ✅ Store and retrieve encrypted secrets
- ✅ Deposit and withdraw ETH
- ✅ Transfer ownership to another address
- ✅ View balance and owner information
- ✅ Type identification

### Box-Specific Features:

#### Basic Deposit Box
- No restrictions
- Instant access to funds
- Perfect for everyday use

#### Premium Deposit Box
- Minimum balance requirement (0.1 ETH)
- Daily withdrawal limit (1 ETH)
- Enhanced security features
- View remaining daily withdrawal allowance

#### Time-Locked Deposit Box
- Funds locked for a specified duration
- Cannot withdraw until lock expires
- Can extend lock period
- View remaining lock time
- Perfect for savings or escrow

### VaultManager Features:
- Create new deposit boxes of any type
- Register existing boxes
- Store/retrieve secrets through the manager
- Deposit funds to boxes
- Transfer box ownership
- Track all user boxes
- Query box information

## 🚀 Usage Examples

### Creating a Deposit Box

```solidity
// Create a basic box
VaultManager manager = VaultManager(managerAddress);
address myBox = manager.createBasicBox();

// Create a premium box
address premiumBox = manager.createPremiumBox();

// Create a time-locked box (locked for 30 days)
address timeLockedBox = manager.createTimeLockedBox(30 days);
```

### Storing a Secret

```solidity
// Direct interaction
IDepositBox box = IDepositBox(boxAddress);
box.storeSecret("My secret data");

// Through the manager
manager.storeSecretInBox(boxAddress, "My secret data");
```

### Depositing Funds

```solidity
// Direct deposit
box.deposit{value: 1 ether}();

// Through the manager
manager.depositToBox{value: 1 ether}(boxAddress);
```

### Withdrawing Funds

```solidity
// Withdraw 0.5 ETH
box.withdraw(0.5 ether);

// Premium box - check remaining daily limit first
PremiumDepositBox premiumBox = PremiumDepositBox(boxAddress);
uint256 remaining = premiumBox.getRemainingDailyWithdrawal();
```

### Transferring Ownership

```solidity
// Direct transfer
box.transferOwnership(newOwnerAddress);

// Through the manager (also updates tracking)
manager.transferBoxOwnership(boxAddress, newOwnerAddress);
```

### Checking Box Information

```solidity
// Get all your boxes
address[] memory myBoxes = manager.getUserBoxes(msg.sender);

// Get box details
(address owner, uint256 balance, string memory boxType) = 
    manager.getBoxInfo(boxAddress);
```

## 🔒 Security Features

1. **Access Control**: Only the box owner can access their secrets and funds
2. **Zero Address Protection**: Prevents setting owner to zero address
3. **Balance Checks**: Ensures sufficient balance before withdrawals
4. **Premium Limits**: Daily withdrawal limits prevent rapid fund drainage
5. **Time Locks**: Enforced lock periods for time-locked boxes
6. **Transfer Safety**: Uses call() with success check for ETH transfers

## 🎓 Educational Value

This project teaches:

1. **Interface Design**: How to define contracts between different parts of a system
2. **Inheritance Hierarchy**: Creating reusable base contracts
3. **Polymorphism**: Different box types can be treated uniformly via the interface
4. **Abstract Contracts**: Implementing partially complete contracts
5. **Function Modifiers**: Creating reusable access control logic
6. **Events**: Logging important state changes for transparency
7. **Contract Interaction**: How contracts call functions on other contracts
8. **Value Transfer**: Sending ETH between contracts safely
9. **Factory Pattern**: Creating multiple instances of contracts dynamically
10. **State Management**: Tracking relationships between contracts

## 🧪 Testing Scenarios

### Scenario 1: Basic Usage Flow
1. Deploy VaultManager
2. Create a basic deposit box
3. Deposit 1 ETH
4. Store a secret
5. Retrieve the secret
6. Withdraw 0.5 ETH
7. Transfer ownership to another address

### Scenario 2: Premium Box Limits
1. Create premium box
2. Deposit 2 ETH
3. Try to withdraw 1.95 ETH (should fail - minimum balance)
4. Withdraw 0.5 ETH (success)
5. Withdraw 0.6 ETH (should fail - daily limit)
6. Check remaining daily limit
7. Wait 1 day and withdraw again

### Scenario 3: Time-Locked Box
1. Create time-locked box with 7 days lock
2. Deposit 5 ETH
3. Try to withdraw immediately (should fail)
4. Check remaining lock time
5. Extend lock by 3 more days
6. Fast-forward time (or wait)
7. Withdraw funds after lock expires

### Scenario 4: Manager Interaction
1. Create multiple boxes of different types
2. Get all user boxes
3. Iterate through boxes and check info
4. Deposit to multiple boxes through manager
5. Transfer ownership of one box
6. Verify tracking updates

## 📊 Gas Optimization Considerations

- Uses `immutable` for lock duration in TimeLockedBox
- Constants for premium box limits
- Efficient storage patterns
- View functions don't consume gas

## 🔧 Deployment

1. Deploy `VaultManager` contract
2. Users interact with VaultManager to create boxes
3. VaultManager deploys box contracts on-demand
4. Each box is independent but manageable through the central system

## 🌟 Extensibility

The system can be easily extended with new box types:

```solidity
contract MultiSigDepositBox is BaseDepositBox {
    // Require multiple signatures for withdrawals
    function getBoxType() external pure override returns (string memory) {
        return "MultiSig";
    }
}

// Add to VaultManager:
function createMultiSigBox() external returns (address) {
    MultiSigDepositBox newBox = new MultiSigDepositBox(msg.sender);
    _registerBox(address(newBox), msg.sender, "MultiSig");
    return address(newBox);
}
```

## 📝 License

MIT License - Feel free to use this for learning and building!

## 🎯 Day 14 Challenge Complete

This implementation covers all required concepts:
- ✅ Interfaces (`IDepositBox`)
- ✅ Abstraction (`BaseDepositBox`)
- ✅ Ownership Transfer (in all box types)
- ✅ Contract-to-contract interaction (`VaultManager`)

Plus additional features:
- Multiple box types with different characteristics
- Comprehensive event logging
- Flexible manager system
- Extensible architecture
- Real-world use case implementation

---

**Happy Banking! 🏦**
