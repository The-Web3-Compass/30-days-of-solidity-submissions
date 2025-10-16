# Modular Profile System for Web3 Games

## Overview

This is a comprehensive example of a **modular profile system** for Web3 games that demonstrates how to use `delegatecall`, code execution context, and libraries to build scalable, extensible smart contracts.

### Key Innovation: Plugin Architecture with delegatecall

The core insight is that instead of putting all game features into one monolithic contract, we separate concerns:

- **GameProfile.sol**: Stores player data (name, avatar, plugins list)
- **Plugins**: Independent contracts that add features (achievements, inventory, battle stats, social)
- **delegatecall**: The bridge that lets plugins run their code while reading/writing profile storage

This architecture allows you to **upgrade features or add new ones without redeploying the main contract**—just deploy new plugins and let players enable them.

---

## Architecture

### 1. Core Contracts

#### **GameProfile.sol** - The Main Profile Contract
The heart of the system. It:
- Stores player profiles (name, avatar, creation date)
- Manages which plugins are enabled for each player
- **Executes plugin functions via delegatecall**
- Maintains a clean API for profile creation and updates

**Key Storage Structure:**
```solidity
struct Profile {
    string name;
    string avatarURI;
    uint256 createdAt;
    bool exists;
}

mapping(address => Profile) public profiles;
mapping(address => address[]) public enabledPlugins;
mapping(address => mapping(address => bool)) public isPluginEnabled;
```

#### **IPlugin.sol** - Plugin Interface
All plugins must implement this interface to ensure consistency:
```solidity
interface IPlugin {
    function version() external pure returns (string memory);
    function name() external pure returns (string memory);
}
```

This allows GameProfile to verify that a contract is actually a valid plugin before enabling it.

---

### 2. Understanding delegatecall

`delegatecall` is the linchpin of this architecture. Let's understand how it differs from regular `call`:

#### Regular `call`:
```solidity
someContract.someFunction()
// - Executes code in someContract
// - Uses someContract's storage
// - msg.sender = the caller
```

#### `delegatecall`:
```solidity
someContract.delegatecall(encodedFunctionCall)
// - Executes code in someContract
// - But uses OUR storage (GameProfile's storage!)
// - msg.sender stays the same
// - Perfect for plugins!
```

**Visual Example:**

```
Player calls GameProfile.executePluginFunction(achievementPlugin, "unlockAchievement(string)", params)

GameProfile.executePluginFunction:
  ┌─────────────────────────────────────────────────────┐
  │ 1. Encode function call: "unlockAchievement(string)"│
  │ 2. Execute: achievementPlugin.delegatecall(encoded) │
  │                                                     │
  │ What happens:                                       │
  │ ├─ AchievementsPlugin.unlockAchievement() runs    │
  │ ├─ But msg.sender = original player               │
  │ ├─ And storage = GameProfile's storage!           │
  │ └─ So achievements get stored in profile           │
  └─────────────────────────────────────────────────────┘
```

#### Why This Matters:

1. **Modularity**: Achievement logic lives in AchievementsPlugin, not GameProfile
2. **Upgradability**: Deploy a new AchievementsPlugin, players switch to it
3. **Cleanness**: GameProfile doesn't need to know HOW achievements work, just that they work
4. **Efficiency**: All data stays in one contract (no cross-contract storage reads)

---

### 3. Libraries

#### **ProfileLib.sol** - Profile Utilities
Provides common functionality for profile management:
```solidity
library ProfileLib {
    // Validation functions
    function validateProfileName(string memory name) internal pure
    function validateAvatarURI(string memory avatarURI) internal pure
    function validatePluginAddress(address pluginAddress) internal pure
    function validateOwner(address caller, address owner) internal pure
    
    // Events and errors shared across contracts
    event PluginEnabled(...)
    event PluginDisabled(...)
}
```

**Why a Library?**
- **Code reuse**: Multiple contracts use these validations
- **Single source of truth**: One place to update validation rules
- **Gas efficiency**: Libraries are often inlined by the compiler
- **Cleaner code**: Separates concerns from business logic

#### **DelegatecallLib.sol** - Safe delegatecall Execution
Encapsulates the complexities of delegatecall:
```solidity
library DelegatecallLib {
    function executeDelegatecall(address target, bytes memory data)
        internal returns (bool success, bytes memory result)
    
    function encodeCall(bytes4 functionSelector, bytes memory encodedParams)
        internal pure returns (bytes memory)
    
    function getSelector(string memory signature)
        internal pure returns (bytes4)
}
```

**Why Abstract delegatecall?**
- **Safety**: Proper error handling, revert propagation
- **Reusability**: Any contract can safely delegatecall
- **Encapsulation**: Hide low-level delegatecall complexity
- **Maintainability**: Fix delegatecall issues in one place

---

### 4. Plugins

Each plugin is a separate contract implementing `IPlugin` and providing specific features.

#### **AchievementsPlugin.sol**
Players can unlock achievements. Features:
```solidity
unlockAchievement(string title, string description)
hasAchievement(string title) returns (bool)
getAchievementCount() returns (uint256)
```

#### **InventoryPlugin.sol**
Players manage items and inventory. Features:
```solidity
addItem(bytes32 itemId, string name, uint256 quantity, string rarity)
removeItem(bytes32 itemId, uint256 quantity)
craftItem(string recipe)
getInventorySpace() returns (uint256 used, uint256 total)
```

#### **BattleStatsPlugin.sol**
Players track combat statistics. Features:
```solidity
getBattleStats() returns (BattleStats memory)
addExperience(uint256 amount)
recordWin(uint256 experienceReward)
recordLoss()
levelUp()
heal(uint256 amount)
takeDamage(uint256 amount)
```

#### **SocialPlugin.sol**
Players interact socially. Features:
```solidity
followPlayer(address playerToFollow)
unfollowPlayer(address playerToUnfollow)
updateBio(string bio)
isFollowing(address follower, address followed) returns (bool)
visitProfile(address profileVisited)
```

---

## Code Execution Context

The key to understanding delegatecall is understanding **execution context**. When a function executes, it operates in a context containing:

1. **msg.sender**: Who called the function
2. **msg.value**: How much ETH was sent
3. **Storage**: Where variables are stored
4. **Code**: The actual bytecode being executed

### Context Comparison:

```solidity
// Regular call - context changes
targetContract.regularFunction()
// context: msg.sender = targetContract, storage = targetContract's

// delegatecall - context stays the same
targetContract.delegatecall(data)
// context: msg.sender = original caller, storage = our storage
```

### In Our System:

```
User (0x1234...)
  │
  └─> GameProfile.createProfile("Alice", "ipfs://...")
       │
       ├─ Storage context = GameProfile
       ├─ msg.sender = User
       └─ Stores profile in GameProfile storage ✓

User calls GameProfile.executePluginFunction(AchievementsPlugin, "unlockAchievement", params)
  │
  └─> GameProfile.executePluginFunction
       │
       ├─ AchievementsPlugin.delegatecall(unlockAchievementCall)
       │  │
       │  └─ AchievementsPlugin code runs
       │     ├─ Storage context = GameProfile (!)
       │     ├─ msg.sender = User (preserved!)
       │     └─ Emits event
       │        └─ Event stored in GameProfile context
       │
       └─ Success! Achievement logic in plugin, data in profile ✓
```

---

## Usage Example

### 1. Create a Profile

```solidity
GameProfile profile = new GameProfile();

profile.createProfile("Alice", "ipfs://QmAlice");
// Profile created with name and avatar
```

### 2. Deploy and Enable a Plugin

```solidity
AchievementsPlugin achievements = new AchievementsPlugin();

profile.enablePlugin(address(achievements));
// Player Alice now has achievements enabled
```

### 3. Call Plugin Functions via delegatecall

```solidity
// Player wants to unlock an achievement
bytes memory params = abi.encode("Boss Slayer", "Defeated the final boss");
profile.executePluginFunction(
    address(achievements),
    "unlockAchievement(string,string)",
    params
);

// This triggers:
// 1. GameProfile encodes the function call
// 2. GameProfile.delegatecall to AchievementsPlugin
// 3. AchievementsPlugin code runs with GameProfile storage
// 4. Achievement data stored in GameProfile
// 5. Event emitted from GameProfile context
```

### 4. Get Multiple Plugins Working

```solidity
BattleStatsPlugin stats = new BattleStatsPlugin();
InventoryPlugin inventory = new InventoryPlugin();

profile.enablePlugin(address(stats));
profile.enablePlugin(address(inventory));

// Now player has all three features enabled:
address[] memory plugins = profile.getEnabledPlugins(msg.sender);
// [achievements, stats, inventory]

// Each plugin can be called independently via delegatecall
profile.executePluginFunction(address(stats), "recordWin(uint256)", abi.encode(1000));
profile.executePluginFunction(address(inventory), "addItem(bytes32,string,uint256,string)", 
    abi.encode(itemId, "Sword", 1, "rare"));
```

---

## Advanced: How to Create a New Plugin

### Step 1: Implement IPlugin Interface

```solidity
contract MyCustomPlugin is IPlugin {
    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "My Custom Plugin";
    }
}
```

### Step 2: Add Your Feature Logic

```solidity
contract MyCustomPlugin is IPlugin {
    // ... interface implementation ...

    event CustomEventHappened(address indexed player, string data);

    function myCustomFeature(string calldata data) external {
        require(bytes(data).length > 0, "Data required");
        emit CustomEventHappened(msg.sender, data);
    }
}
```

### Step 3: Users Can Enable It

```solidity
MyCustomPlugin myPlugin = new MyCustomPlugin();
gameProfile.enablePlugin(address(myPlugin));

// Now call it
bytes memory params = abi.encode("some data");
gameProfile.executePluginFunction(
    address(myPlugin),
    "myCustomFeature(string)",
    params
);
```

---

## Storage Layout Considerations

### ⚠️ Important: Storage Collision Risk

When using delegatecall, all contracts share the same storage space. This creates a risk of storage collision:

```solidity
// GameProfile.sol
contract GameProfile {
    mapping(address => Profile) public profiles;  // Slot 0
    mapping(address => address[]) public enabledPlugins;  // Slot 1
    // ... more storage slots ...
}

// AchievementsPlugin.sol
contract AchievementsPlugin {
    // If we use slot 0 here, it collides with profiles!
    mapping(address => Achievement[]) achievements;  // ❌ Conflicts!
}
```

### Solution: Organized Storage Layout

In production, you'd typically:

1. **Reserve slots for GameProfile**: Slots 0-50
2. **Reserve slots for each plugin**: Slots 100+
3. **Document storage layout**: Keep a registry of which plugin uses which slots

Or use **Diamond Proxy Pattern** or **EIP-1967 Storage Layout**.

For this example, we've kept plugins simple to focus on the delegatecall concept, but in production, implement proper storage management!

---

## Gas Efficiency

### Benefits of This Architecture

1. **Single Storage Location**: All data in one contract (GameProfile)
   - No cross-contract storage reads
   - No multiple `SLOAD` calls
   - Lower gas costs

2. **Modular Code**: Features not used aren't deployed
   - Only pay gas for features you need
   - Unused plugins don't cost gas

3. **Upgradeable Logic**: Fix bugs by deploying new plugin
   - Don't need to migrate storage
   - Don't need to redeploy everything
   - Minimal disruption

### Vs. Other Approaches

```
Traditional Monolithic Contract:
├─ All features in one file
├─ Growing bytecode size
├─ Can't upgrade individual features
├─ Hard to maintain
└─ High deployment costs

This Plugin System:
├─ Modular, each plugin separate
├─ Small core contract
├─ Upgrade one feature at a time
├─ Easy to maintain
└─ Lower ongoing costs
```

---

## Security Considerations

### delegatecall Risks

1. **Storage Collision**: Plugins overwrite GameProfile data if not careful
   - **Mitigation**: Use separate storage slots for plugins
   - **Best Practice**: Use assembly for explicit slot management

2. **Malicious Plugins**: A bad plugin could steal profile data
   - **Mitigation**: Only enable plugins you trust
   - **Mitigation**: Audit plugin code before enabling
   - **Note**: Players control which plugins they enable

3. **Reentrancy**: Plugins could re-enter GameProfile
   - **Mitigation**: Use checks-effects-interactions pattern
   - **Mitigation**: Consider reentrancy guards

### Safety Features in Our Code

- **Plugin Validation**: `IPlugin` interface ensures basic structure
- **Access Control**: Only profile owner can enable plugins
- **Error Handling**: Proper revert propagation from delegatecall
- **Event Logging**: All plugin calls are emitted and logged

---

## Extension Ideas

### Add These Features to Extend the System

1. **Plugin Dependency System**
   - Some plugins depend on others
   - Example: Leaderboard plugin needs BattleStats

2. **Plugin Versioning**
   - Deprecate old plugins
   - Force upgrades for security

3. **Plugin Permissions**
   - Fine-grained control over what plugins can do
   - Example: Some plugins can read-only, others can modify

4. **Cross-Plugin Communication**
   - Plugins call each other's functions
   - Achievements trigger based on inventory changes

5. **Plugin Settings**
   - Players customize plugin behavior
   - Enable/disable specific plugin features

6. **Plugin Events Registry**
   - Plugins emit standardized events
   - Game UI can listen and react

---

## Files Structure

```
Day16/
├── contracts/
│   ├── GameProfile.sol          # Main profile contract with delegatecall execution
│   └── IPlugin.sol              # Plugin interface that all plugins implement
├── libraries/
│   ├── ProfileLib.sol           # Profile utilities and validation
│   └── DelegatecallLib.sol      # Safe delegatecall execution library
├── plugins/
│   ├── AchievementsPlugin.sol   # Achievement tracking plugin
│   ├── InventoryPlugin.sol      # Inventory management plugin
│   ├── BattleStatsPlugin.sol    # Combat stats plugin
│   └── SocialPlugin.sol         # Social interactions plugin
└── README.md                     # This file
```

---

## Testing Strategy

### Test Structure

```solidity
// Test creating a profile
GameProfile profile = new GameProfile();
profile.createProfile("TestPlayer", "ipfs://test");
assert(profile.profiles(msg.sender).exists);

// Test enabling a plugin
AchievementsPlugin achievements = new AchievementsPlugin();
profile.enablePlugin(address(achievements));
assert(profile.isPluginEnabled(msg.sender, address(achievements)));

// Test plugin execution via delegatecall
bytes memory result = profile.executePluginFunction(
    address(achievements),
    "unlockAchievement(string,string)",
    abi.encode("First Kill", "Your first opponent defeated")
);

// Test multiple plugins
BattleStatsPlugin stats = new BattleStatsPlugin();
profile.enablePlugin(address(stats));
profile.executePluginFunction(address(stats), "recordWin(uint256)", abi.encode(1000));
```

---

## Key Learning Takeaways

### delegatecall
- Executes external code with your storage context
- Perfect for modular plugin systems
- Essential for proxy patterns and upgradeable contracts
- Requires careful storage layout planning

### Execution Context
- `msg.sender`, `msg.value`, storage are part of execution context
- `delegatecall` preserves caller context
- `call` changes context to target contract
- Understanding context is crucial for smart contract security

### Libraries
- Code reuse and organization
- Gas efficient (often inlined)
- Good for shared utilities and validations
- Can contain events and error definitions

### Modular Architecture
- Separate concerns into different contracts
- Plugin pattern enables easy upgrades
- Reduces contract size and complexity
- Improves maintainability

---

## Conclusion

This modular profile system showcases a production-grade pattern for building scalable Web3 games. By combining `delegatecall`, proper libraries, and a clear plugin architecture, you can build:

- **Upgradeable** systems without data migration
- **Modular** features that can be added independently
- **Efficient** contracts that keep data centralized
- **Maintainable** codebases that are easy to extend

The key insight is that **delegatecall** lets you separate code (in plugins) from storage (in profile), enabling powerful architectural patterns that scale to complex applications.

Happy building! 🎮
