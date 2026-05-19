# Gas Optimization Techniques - Visual Guide

## 📊 Storage Layout Comparison

### Unoptimized Storage Layout

```
┌─────────────────────────────────────┐
│ Slot 0: address proposer (20 bytes) │ ← Wastes 12 bytes
├─────────────────────────────────────┤
│ Slot 1: uint256 id (32 bytes)       │
├─────────────────────────────────────┤
│ Slot 2: uint256 endTime (32 bytes)  │
├─────────────────────────────────────┤
│ Slot 3: bool executed (1 byte)      │ ← Wastes 31 bytes
├─────────────────────────────────────┤
│ Slot 4: uint256 yesVotes (32 bytes) │
├─────────────────────────────────────┤
│ Slot 5: uint256 noVotes (32 bytes)  │
├─────────────────────────────────────┤
│ Slot 6: string description (32+)    │ ← Very expensive!
└─────────────────────────────────────┘

Total: 7+ storage slots
Cost: ~140,000+ gas for creation
```

### Optimized Storage Layout (GasSaver)

```
┌──────────────────────────────────────────────────┐
│ Slot 0: address proposer (20 bytes)              │
│         uint32 id (4 bytes)                      │
│         uint32 endTime (4 bytes)                 │
│         bool executed (1 byte)                   │
│         [3 bytes padding]                        │
├──────────────────────────────────────────────────┤
│ Slot 1: uint256 yesVotes (32 bytes)             │
├──────────────────────────────────────────────────┤
│ Slot 2: uint256 noVotes (32 bytes)              │
└──────────────────────────────────────────────────┘

Description stored in events (logs), not storage!

Total: 3 storage slots
Cost: ~60,000 gas for creation
Savings: 57% reduction in gas cost!
```

## 🔢 Voter State Bit-Packing

### Traditional Approach (2 Storage Slots)

```
Voter State for Address 0x123...abc

┌─────────────────────────────────────┐
│ hasVoted[proposalId][voter]         │
│ = true                              │
│ Cost: 20,000 gas (new storage)      │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ voteChoice[proposalId][voter]       │
│ = true (yes vote)                   │
│ Cost: 20,000 gas (new storage)      │
└─────────────────────────────────────┘

Total: 40,000 gas
```

### Bit-Packed Approach (1 Storage Slot)

```
Voter State for Address 0x123...abc

┌─────────────────────────────────────┐
│ voterState[proposalId][voter]       │
│ = 3 (binary: 0b11)                  │
│                                     │
│ Bit 0 (LSB): 1 = has voted         │
│ Bit 1:       1 = yes vote          │
│                                     │
│ Cost: 20,000 gas (new storage)      │
└─────────────────────────────────────┘

Total: 20,000 gas
Savings: 50% reduction!
```

### Decoding Bit-Packed Data

```solidity
uint256 state = voterState[proposalId][voter];

// Check if voted (bit 0)
bool hasVoted = (state & 1) == 1;
// 3 & 1 = 0b11 & 0b01 = 0b01 = 1 ✓

// Check vote choice (bit 1)
bool support = (state & 2) == 2;
// 3 & 2 = 0b11 & 0b10 = 0b10 = 2 ✓
```

## 📦 Data Location: Calldata vs Memory vs Storage

### Example: String Parameter

```solidity
// ❌ BAD: Memory (requires copying)
function createProposal(string memory description) {
    // 1. Copy from calldata to memory: ~2,000 gas
    // 2. Use the copy: minimal cost
    // Total: ~2,000+ gas overhead
}

// ✅ GOOD: Calldata (direct reference)
function createProposal(string calldata description) {
    // 1. Reference calldata directly: ~3 gas per read
    // 2. No copying needed
    // Total: minimal overhead
}

// Savings: ~2,000 gas per call
```

### Visual Representation

```
Transaction Data (Calldata)
┌────────────────────────────┐
│ Function Selector          │
│ Parameter: "My Proposal"   │ ← Data already here
└────────────────────────────┘
              │
              │ string memory
              ├──────────────────────┐
              │ COPY (expensive!)    │
              ▼                      │
        ┌──────────┐                │
        │  Memory  │                │
        │  Copy    │                │
        └──────────┘                │
                                    │
              │ string calldata     │
              ├──────────────────────┘
              │ REFERENCE (cheap!)
              ▼
        (Use directly)
```

## 💾 Immutable vs Storage

### Storage Variable (Traditional)

```
Contract Storage
┌─────────────────────────────────────┐
│ Slot X: owner address               │
│ Read cost: 2,100 gas (cold)         │
│ Read cost: 100 gas (warm)           │
└─────────────────────────────────────┘

Multiple reads in contract:
- First read: 2,100 gas
- Subsequent: 100 gas each
- 10 reads: 3,000 gas total
```

### Immutable Variable (Optimized)

```
Contract Bytecode
┌─────────────────────────────────────┐
│ [...code...]                        │
│ PUSH20 0x123...abc  ← owner address │
│ [...code...]                        │
│ Read cost: ~3 gas                   │
└─────────────────────────────────────┘

Multiple reads in contract:
- Each read: ~3 gas
- 10 reads: ~30 gas total

Savings: ~99% reduction!
```

## 🔄 Storage Caching

### Without Caching

```solidity
function createProposal() {
    proposalCount++;           // SLOAD + SSTORE
    uint256 id = proposalCount; // SLOAD (again!)
    // ...
    
    // Total: 2 SLOADs + 1 SSTORE
    // Cost: ~25,000 gas
}
```

### With Caching

```solidity
function createProposal() {
    uint32 count = proposalCount; // SLOAD (once)
    count++;
    uint32 id = count;            // Local var (cheap)
    // ...
    proposalCount = count;        // SSTORE (once)
    
    // Total: 1 SLOAD + 1 SSTORE
    // Cost: ~23,000 gas
    // Savings: ~2,000 gas
}
```

## 🔁 Loop Optimizations

### Unoptimized Loop

```solidity
function batchVote(uint256[] memory ids, bool[] memory votes) {
    for (uint256 i = 0; i < ids.length; i++) {
        // ids.length read every iteration: expensive!
        // i++ with overflow check: adds ~100 gas
        vote(ids[i], votes[i]);
    }
}

// 5 iterations cost: ~300 gas overhead
```

### Optimized Loop

```solidity
function batchVote(uint256[] calldata ids, bool[] calldata votes) {
    uint256 length = ids.length; // Cache length: read once
    
    for (uint256 i; i < length;) {
        vote(ids[i], votes[i]);
        
        unchecked {
            ++i; // No overflow check: safe and cheaper
        }
    }
}

// 5 iterations cost: ~100 gas overhead
// Savings: ~200 gas for 5 iterations
```

## 📈 Gas Cost Breakdown

### Creating a Proposal

```
Unoptimized Approach:
┌──────────────────────────────┬──────────┐
│ Transaction base cost        │ 21,000   │
├──────────────────────────────┼──────────┤
│ Storage slots (7)            │ 140,000  │
├──────────────────────────────┼──────────┤
│ String storage (100 chars)   │  60,000  │
├──────────────────────────────┼──────────┤
│ Function execution           │   5,000  │
├──────────────────────────────┼──────────┤
│ TOTAL                        │ 226,000  │
└──────────────────────────────┴──────────┘

Optimized Approach (GasSaver):
┌──────────────────────────────┬──────────┐
│ Transaction base cost        │ 21,000   │
├──────────────────────────────┼──────────┤
│ Storage slots (3)            │ 60,000   │
├──────────────────────────────┼──────────┤
│ Event emission (100 chars)   │  3,000   │
├──────────────────────────────┼──────────┤
│ Function execution           │   3,000  │
├──────────────────────────────┼──────────┤
│ TOTAL                        │ 87,000   │
└──────────────────────────────┴──────────┘

💰 SAVINGS: 139,000 gas (61% reduction!)
```

### Voting

```
Unoptimized:
┌──────────────────────────────┬──────────┐
│ Transaction base             │ 21,000   │
│ hasVoted storage             │ 20,000   │
│ voteChoice storage           │ 20,000   │
│ Vote count update            │  5,000   │
│ Validation checks            │  3,000   │
├──────────────────────────────┼──────────┤
│ TOTAL                        │ 69,000   │
└──────────────────────────────┴──────────┘

Optimized:
┌──────────────────────────────┬──────────┐
│ Transaction base             │ 21,000   │
│ Voter state (bit-packed)     │ 20,000   │
│ Vote count update            │  5,000   │
│ Validation checks            │  2,000   │
├──────────────────────────────┼──────────┤
│ TOTAL                        │ 48,000   │
└──────────────────────────────┴──────────┘

💰 SAVINGS: 21,000 gas (30% reduction!)
```

## 🎯 Optimization Priority

```
High Impact (Do First)
├─ ⭐⭐⭐⭐⭐ Store large data in events, not storage
├─ ⭐⭐⭐⭐⭐ Pack storage variables
├─ ⭐⭐⭐⭐⭐ Use calldata for function parameters
└─ ⭐⭐⭐⭐⭐ Use immutable for constants

Medium Impact
├─ ⭐⭐⭐ Cache storage reads
├─ ⭐⭐⭐ Bit-pack boolean states
├─ ⭐⭐⭐ Use smaller uint types (uint32, uint64)
└─ ⭐⭐⭐ Batch operations

Low Impact (Polish)
├─ ⭐⭐ Unchecked arithmetic in loops
├─ ⭐⭐ Cache array length
├─ ⭐ Use prefix increment (++i vs i++)
└─ ⭐ Early validation (fail fast)
```

## 💡 Quick Reference

### Data Location Keywords

| Keyword | Cost | Use Case |
|---------|------|----------|
| `storage` | 💰💰💰 Expensive | State variables, persistent data |
| `memory` | 💰💰 Medium | Function-local temporary data |
| `calldata` | 💰 Cheap | Read-only function parameters |

### Gas Costs (Approximate)

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| SSTORE (new) | 20,000 | First write to storage slot |
| SSTORE (update) | 2,900 | Updating existing slot |
| SLOAD (cold) | 2,100 | First read from slot |
| SLOAD (warm) | 100 | Subsequent reads |
| Memory expansion | 3/word | Grows quadratically |
| Calldata read | 3 | Very cheap |
| LOG (event) | 375 + 8/byte | Much cheaper than storage |

### Bit Manipulation Cheat Sheet

```solidity
// Set bit n to 1
value |= (1 << n);

// Set bit n to 0
value &= ~(1 << n);

// Check if bit n is set
bool isSet = (value & (1 << n)) != 0;

// Toggle bit n
value ^= (1 << n);

// Multiple flags in one uint256
uint256 flags = 0;
flags |= (1 << 0);  // Set flag 0
flags |= (1 << 1);  // Set flag 1
bool flag0 = (flags & 1) == 1;
bool flag1 = (flags & 2) == 2;
```

---

🎓 **Remember**: Always measure actual gas costs in your specific use case. These optimizations compound for significant savings at scale!
