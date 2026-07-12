# Quick Reference: Modular Profile System

## File Structure

```
Day16/
├── contracts/
│   ├── GameProfile.sol          # Main profile contract - heart of the system
│   └── IPlugin.sol              # Plugin interface
├── libraries/
│   ├── ProfileLib.sol           # Validation & utilities
│   └── DelegatecallLib.sol      # Safe delegatecall wrapper
├── plugins/
│   ├── AchievementsPlugin.sol   # Achievements feature
│   ├── InventoryPlugin.sol      # Inventory feature
│   ├── BattleStatsPlugin.sol    # Battle stats feature
│   └── SocialPlugin.sol         # Social interactions feature
├── PluginStore.sol              # Plugin registry & management
└── README.md                    # Full documentation
```

## Key Concepts

### 1. delegatecall - The Magic Opcode
```solidity
// Regular call: code runs in target's context
targetContract.someFunction()

// delegatecall: code runs in our context
targetContract.delegatecall(encodedFunctionCall)
// - Uses OUR storage
// - msg.sender stays the same
// - Perfect for plugins!
```

### 2. Execution Context
When a function executes, it has:
- `msg.sender` - who called it
- `msg.value` - ETH amount
- Storage - where data lives
- Code - the bytecode

delegatecall preserves sender/storage/value!

### 3. The Plugin Pattern
```
GameProfile (storage owner)
    ↓ delegatecall
Plugin (code provider)
    ↓ executes with GameProfile's storage
Result: Feature logic in plugin, data in profile!
```

## Usage Examples

### Create a Profile
```solidity
GameProfile gp = new GameProfile();
gp.createProfile("Alice", "ipfs://avatar.png");
```

### Enable a Plugin
```solidity
AchievementsPlugin achievements = new AchievementsPlugin();
gp.enablePlugin(address(achievements));
```

### Call Plugin Function
```solidity
// Method 1: Full encoding
bytes memory params = abi.encode("Boss Slayer", "Defeated boss");
gp.executePluginFunction(
    address(achievements),
    "unlockAchievement(string,string)",
    params
);

// Method 2: Simple call (no params)
gp.executePluginFunctionSimple(
    address(stats),
    "levelUp()"
);
```

## Library Features

### ProfileLib.sol
```solidity
// Validation functions
validateProfileName(string memory name)        // Checks name is valid
validateAvatarURI(string memory avatarURI)     // Checks URI length
validatePluginAddress(address pluginAddress)   // Checks not zero
validateOwner(address caller, address owner)   // Checks ownership

// Events & Errors
event PluginEnabled(address indexed player, address indexed pluginAddress)
event ProfileUpdated(address indexed player, string name, string avatar)
error InvalidProfileName(string reason)
```

### DelegatecallLib.sol
```solidity
// Core functions
executeDelegatecall(address target, bytes memory data)
    → (bool success, bytes memory result)
    // Safely executes delegatecall with error handling

encodeCall(bytes4 functionSelector, bytes memory encodedParams)
    → bytes memory
    // Encodes a function call for delegatecall

getSelector(string memory signature)
    → bytes4
    // Gets function selector from signature string
```

## Plugin Implementation Template

```solidity
pragma solidity ^0.8.30;
import "../contracts/IPlugin.sol";

contract MyPlugin is IPlugin {
    // Required by IPlugin
    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "My Plugin Name";
    }

    // Your feature logic
    event MyEventHappened(address indexed player, string data);

    function myFeature(string calldata data) external {
        // When called via delegatecall:
        // - msg.sender = the player
        // - Storage = GameProfile's storage
        // - Can read/write profile data!
        emit MyEventHappened(msg.sender, data);
    }
}
```

## GameProfile Core Functions

### Profile Management
```solidity
createProfile(string calldata _name, string calldata _avatarURI)
    // Create a new profile

updateProfile(string calldata _name, string calldata _avatarURI)
    // Update existing profile

getProfile(address _player) 
    → Profile memory
    // Get player's profile data
```

### Plugin Management
```solidity
enablePlugin(address _plugin)
    // Enable a plugin for your profile

disablePlugin(address _plugin)
    // Disable a plugin

getEnabledPlugins(address _player)
    → address[]
    // List all enabled plugins
```

### Plugin Execution (delegatecall)
```solidity
executePluginFunction(
    address _plugin,
    string calldata _functionSignature,
    bytes calldata _params
) → bytes memory
    // Execute plugin function via delegatecall

executePluginFunctionSimple(
    address _plugin,
    string calldata _functionSignature
) → bytes memory
    // Simpler version for functions with no params
```

## Available Plugins

### AchievementsPlugin
```solidity
unlockAchievement(string title, string description)
hasAchievement(string title) → bool
getAchievementCount() → uint256
```

### InventoryPlugin
```solidity
addItem(bytes32 itemId, string name, uint256 quantity, string rarity)
removeItem(bytes32 itemId, uint256 quantity)
craftItem(string recipe)
getInventorySpace() → (uint256 used, uint256 total)
```

### BattleStatsPlugin
```solidity
getBattleStats() → BattleStats
addExperience(uint256 amount)
recordWin(uint256 experienceReward)
recordLoss()
levelUp()
heal(uint256 amount)
takeDamage(uint256 amount)
```

### SocialPlugin
```solidity
followPlayer(address playerToFollow)
unfollowPlayer(address playerToUnfollow)
updateBio(string bio)
isFollowing(address follower, address followed) → bool
getFollowerCount(address player) → uint256
visitProfile(address profileVisited)
```

## Important Notes

### Storage Layout
⚠️ When using delegatecall, storage slots are shared!
- GameProfile uses slots 0-6
- Plugins should use slots 100+ to avoid collisions
- In production, carefully document storage layout

### Security
✓ Only profile owner can enable/disable plugins
✓ Plugin must implement IPlugin interface
✓ Plugins are trusted contracts (audit before enabling)
✓ delegatecall errors properly propagate

### Gas Efficiency
✓ All data in one contract = fewer SLOAD ops
✓ Plugins only deployed if used
✓ Upgrade plugins without migrating data
✓ Lower ongoing costs than monolithic approach

## Extending the System

### Add a New Plugin
1. Create contract implementing `IPlugin`
2. Implement `version()` and `name()` 
3. Add your feature functions
4. Deploy and enable for profile

### Improve Plugin Discovery
Use `PluginStore.sol`:
```solidity
pluginStore.submitCommunityPlugin(address(plugin), "Name", "Description")
// Submit plugin for approval

pluginStore.approveCommunityPlugin(address(plugin))
// Approve plugin (governance)

pluginStore.getOfficialPlugins()
// Discover official plugins
```

## Common Errors & Solutions

### "Profile does not exist"
→ Call `createProfile()` first

### "Plugin not enabled"
→ Call `enablePlugin()` before executing plugin functions

### "Invalid plugin address"
→ Make sure plugin implements `IPlugin` interface

### Storage collision
→ Use separate storage slots for plugins in production

## Testing Tips

1. Create profile
2. Deploy plugin
3. Enable plugin
4. Call plugin function
5. Verify events emitted
6. Check storage updated

```solidity
// Example test flow
GameProfile gp = new GameProfile();
gp.createProfile("TestUser", "ipfs://test");

BattleStats stats = new BattleStats();
gp.enablePlugin(address(stats));

gp.executePluginFunction(
    address(stats),
    "recordWin(uint256)",
    abi.encode(1000)
);
// Verify StatsUpdated event was emitted
```

## Further Learning

- **delegatecall risks**: Study storage collision issues
- **Diamond Proxy**: Learn advanced multi-plugin pattern
- **EIP-1967**: Understand storage layout standards  
- **Upgradeable Contracts**: Pattern for safe upgrading
- **Access Control**: Add admin features to PluginStore

---

*This is a production-grade pattern for scalable Web3 games!* 🎮
