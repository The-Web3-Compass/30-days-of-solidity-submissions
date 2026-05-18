# High-Level Specification: Day 14 - SafeDeposit System

## 1. Objective
Build a Modular Vault Factory capable of deploying specialized storage units while maintaining a unified interface.

This architecture ensures loose coupling: `VaultManager` can interact with any future vault type (for example, NFT Vaults or DAO Vaults) without requiring manager code changes, as long as the new vault follows the `IDepositBox` interface.

## 2. Design Patterns Used

### Factory Pattern
`VaultManager` acts as a factory that deploys and tracks multiple vault instances.

### Template Pattern
`BaseDepositBox` provides the shared skeleton (ownership, secret storage, deposit timestamp, access control), while child contracts add specialized behavior.

### Polymorphism
All vaults are managed through the generic `IDepositBox` type, enabling flexible and extensible vault management.

## 3. The Three-Tier Inheritance Tree

### Layer 1: Interface (`IDepositBox`)
Role: Contract of truth.

Requirement: Defines the required external API every vault must support.

Impact: Guarantees that frontends and third-party integrations can interact with any compliant `$WATERS` vault using one consistent interface.

### Layer 2: Abstract Base (`BaseDepositBox`)
Role: Engine room.

Implementation: Encapsulates shared state (`owner`, `secret`, `depositTime`) and core access control (`onlyOwner`).

Impact: Reduces duplication and enforces a consistent storage layout across implementations.

### Layer 3: Concrete Implementations (`VaultImplementations`)
- `BasicDepositBox`: Lightweight secret storage.
- `PremiumDepositBox`: Adds metadata mapping for organization.
- `TimeLockedDepositBox`: Adds a time gate via `unlockTime` and `timeUnlocked`.

Behavioral impact: Users can store data immediately, but `TimeLockedDepositBox` prevents secret reads until the unlock condition is satisfied.

## 4. Security Considerations

### Access Control
Sensitive actions are gated by `onlyOwner`.

### Time Manipulation Risk
`TimeLockedDepositBox` relies on `block.timestamp`. Miners/validators can slightly influence timestamps, but this is generally acceptable for lock periods larger than a few minutes.

### Storage Integrity and Encapsulation
Critical state is private in the base contract to prevent accidental mutation by child contracts and preserve predictable storage behavior.

## 5. Implementation Workflow
1. Populate Day 14 contracts in `submissions/rainwaters11/day-14/`.
2. Compile and verify the build (for this workspace, use your preferred Foundry or `solcjs` flow).
3. Deploy `VaultManager`.
4. Create and manage your first `TimeLockedDepositBox` vault instance.

## 6. Expected Outcome
A modular, extensible vault system where new vault types can be introduced without breaking manager-level integrations, provided they implement `IDepositBox`.
