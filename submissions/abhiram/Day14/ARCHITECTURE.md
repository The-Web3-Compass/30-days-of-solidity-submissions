# Smart Bank System - Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER / EXTERNAL CALLER                       │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │ Interacts with
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          VaultManager                                │
│  - Creates new deposit boxes                                         │
│  - Tracks all boxes and ownership                                    │
│  - Provides unified interface for all box types                      │
│  - Facilitates ownership transfers                                   │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 │ Creates & Manages
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Basic   │  │ Premium │  │  Time   │
│  Box    │  │   Box   │  │ Locked  │
└─────────┘  └─────────┘  └─────────┘
    │            │            │
    │            │            │
    └────────────┼────────────┘
                 │
                 │ All implement
                 ▼
        ┌─────────────────┐
        │  IDepositBox    │ ◄────────────────┐
        │   (Interface)   │                  │
        └─────────────────┘                  │
                 ▲                           │
                 │ Defines contract         │ Inherits
                 │                           │
        ┌─────────────────┐                  │
        │ BaseDepositBox  │──────────────────┘
        │   (Abstract)    │
        │ Common Logic:   │
        │ - Ownership     │
        │ - Secrets       │
        │ - Deposits      │
        │ - Withdrawals   │
        └─────────────────┘
```

## Contract Interaction Flow

### 1. Creating a Deposit Box

```
User ──[createBasicBox()]──► VaultManager
                                   │
                                   │ Deploys
                                   ▼
                            BasicDepositBox
                                   │
                                   │ Registers
                                   ▼
                            VaultManager Storage
                              - userBoxes[]
                              - allBoxes[]
                                   │
                                   │ Returns
                                   ▼
                                 User
```

### 2. Storing a Secret

```
Option A: Direct Interaction
───────────────────────────
User ──[storeSecret()]──► DepositBox ──[emit SecretStored]──► Blockchain


Option B: Through Manager
─────────────────────────
User ──[storeSecretInBox()]──► VaultManager
                                     │
                                     │ Validates ownership
                                     │ Calls box.storeSecret()
                                     ▼
                               DepositBox ──[emit SecretStored]──► Blockchain
```

### 3. Depositing Funds

```
User ──[deposit{value: 1 ETH}]──► DepositBox
                                       │
                                       │ Updates balance
                                       │ Stores ETH
                                       │
                                       ▼
                                  [emit Deposited] ──► Blockchain
```

### 4. Ownership Transfer

```
User ──[transferBoxOwnership()]──► VaultManager
                                        │
                                        │ Validates current owner
                                        │
                                        ▼
                                  DepositBox.transferOwnership()
                                        │
                                        │ Changes owner
                                        │
                                        ▼
                                  [emit OwnershipTransferred]
                                        │
                                        ▼
                              VaultManager updates tracking
                                        │
                                        ▼
                              [emit DepositBoxRegistered]
```

## Inheritance Hierarchy

```
                    IDepositBox (Interface)
                          │
                          │ implements
                          ▼
                  BaseDepositBox (Abstract)
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
BasicDepositBox   PremiumDepositBox   TimeLockedDepositBox
     │                  │                   │
     │                  │                   │
     └──────────────────┴───────────────────┘
                        │
                All managed by
                        │
                        ▼
                  VaultManager
```

## Data Flow

### Reading Box Information

```
External Call ──► VaultManager.getBoxInfo()
                       │
                       │ Calls interface methods
                       │
                       ├──► box.getOwner()
                       ├──► box.getBalance()
                       └──► box.getBoxType()
                              │
                              │ Returns tuple
                              ▼
                         (owner, balance, type)
                              │
                              │ Returns to
                              ▼
                          External Caller
```

## Security Model

```
┌────────────────────────────────────────────────┐
│              Access Control Layer              │
├────────────────────────────────────────────────┤
│                                                │
│  onlyOwner Modifier                            │
│  ├── Checks msg.sender == _owner               │
│  └── Used by:                                  │
│      ├── storeSecret()                         │
│      ├── retrieveSecret()                      │
│      ├── withdraw()                            │
│      └── transferOwnership()                   │
│                                                │
├────────────────────────────────────────────────┤
│              Validation Layer                  │
├────────────────────────────────────────────────┤
│                                                │
│  ├── Zero address checks                       │
│  ├── Balance sufficiency checks                │
│  ├── Amount > 0 checks                         │
│  └── Registration checks (VaultManager)        │
│                                                │
├────────────────────────────────────────────────┤
│            Type-Specific Rules                 │
├────────────────────────────────────────────────┤
│                                                │
│  Premium Box:                                  │
│  ├── Minimum balance requirement               │
│  └── Daily withdrawal limits                   │
│                                                │
│  Time-Locked Box:                              │
│  └── Lock period enforcement                   │
│                                                │
└────────────────────────────────────────────────┘
```

## Box Type Comparison

| Feature                | Basic | Premium | Time-Locked |
|------------------------|-------|---------|-------------|
| Store Secrets          | ✅    | ✅      | ✅          |
| Deposit ETH            | ✅    | ✅      | ✅          |
| Instant Withdrawal     | ✅    | ⚠️*     | ❌**        |
| Ownership Transfer     | ✅    | ✅      | ✅          |
| Minimum Balance        | ❌    | ✅      | ❌          |
| Daily Limit            | ❌    | ✅      | ❌          |
| Time Lock              | ❌    | ❌      | ✅          |

*Premium: Subject to daily limits and minimum balance  
**Time-Locked: Only after lock expires

## Event Emission Flow

```
Action                  Event Emitted               Data Included
──────                  ─────────────               ─────────────
storeSecret()       ──► SecretStored            ──► owner, timestamp
deposit()           ──► Deposited               ──► depositor, amount
withdraw()          ──► Withdrawn               ──► owner, amount
transferOwnership() ──► OwnershipTransferred   ──► previousOwner, newOwner
createBox()         ──► DepositBoxCreated       ──► boxAddress, owner, type, timestamp
registerBox()       ──► DepositBoxRegistered    ──► boxAddress, owner
```

## State Management

### DepositBox State

```
┌─────────────────────────────┐
│     DepositBox State        │
├─────────────────────────────┤
│ _owner: address             │
│ _secret: string             │
│ _balance: uint256           │
│                             │
│ Premium Box adds:           │
│ ├── _lastWithdrawalDay      │
│ └── _dailyWithdrawnAmount   │
│                             │
│ TimeLocked Box adds:        │
│ ├── lockDuration (immutable)│
│ └── lockEndTime             │
└─────────────────────────────┘
```

### VaultManager State

```
┌──────────────────────────────────┐
│     VaultManager State           │
├──────────────────────────────────┤
│ userBoxes: mapping(              │
│   address => address[]           │
│ )                                │
│                                  │
│ isRegisteredBox: mapping(        │
│   address => bool                │
│ )                                │
│                                  │
│ allBoxes: address[]              │
└──────────────────────────────────┘
```

## Complete User Journey

```
1. User deploys or connects to VaultManager
   │
   ▼
2. User creates a deposit box
   ├── Basic (no restrictions)
   ├── Premium (enhanced security)
   └── Time-Locked (savings/escrow)
   │
   ▼
3. User deposits ETH and stores secrets
   │
   ▼
4. User can check balance and box info
   │
   ▼
5. User withdraws (subject to box rules)
   │
   ▼
6. User can transfer ownership
   │
   ▼
7. New owner has full control
```

## Extensibility Pattern

```
Need a new box type?
   │
   ▼
1. Create new contract extending BaseDepositBox
   │
   ▼
2. Override functions to add custom logic
   │
   ▼
3. Implement getBoxType()
   │
   ▼
4. Add creation function to VaultManager
   │
   ▼
5. Deploy and use!
```

Example:
```solidity
contract MultiSigDepositBox is BaseDepositBox {
    mapping(address => bool) public signers;
    uint256 public requiredSignatures;
    
    function withdraw(uint256 amount) external override {
        // Custom multi-sig logic
        require(hasEnoughSignatures(), "Need more signatures");
        _withdraw(amount);
    }
    
    function getBoxType() external pure override returns (string memory) {
        return "MultiSig";
    }
}
```

---

This architecture provides:
- **Modularity**: Each component has a single responsibility
- **Flexibility**: Easy to add new box types
- **Security**: Multiple layers of protection
- **Transparency**: Comprehensive event logging
- **Usability**: Both direct and managed interactions supported
