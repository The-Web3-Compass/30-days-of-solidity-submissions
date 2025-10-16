# Architecture Overview: Modular Web3 Game Profile System

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        GAME ECOSYSTEM                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              PLUGIN STORE (Registry)                     │   │
│  │  - Discovers official plugins                           │   │
│  │  - Manages community plugins                            │   │
│  │  - Handles plugin downloads/installation                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                      │
│                           │ manages                              │
│                           ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         GAME PROFILE (Storage + Orchestrator)            │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │ Storage:                                           │  │   │
│  │  │  - Player name, avatar                            │  │   │
│  │  │  - Enabled plugins list                           │  │   │
│  │  │  - All achievement data (via delegatecall)        │  │   │
│  │  │  - All inventory data (via delegatecall)          │  │   │
│  │  │  - All battle stats data (via delegatecall)       │  │   │
│  │  │  - All social data (via delegatecall)            │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │ Functions:                                         │  │   │
│  │  │  - createProfile(name, avatar)                    │  │   │
│  │  │  - enablePlugin(plugin)                           │  │   │
│  │  │  - executePluginFunction(plugin, func, params)    │  │   │
│  │  │    └─> Uses DELEGATECALL!                         │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│          ▲                  ▲                   ▲               │
│          │ delegatecall     │ delegatecall      │ delegatecall  │
│          │                  │                   │               │
│  ┌───────┴──┐   ┌──────────┴──┐   ┌───────────┴───┐   ┌─────┴─────┐
│  │ACHIEVEMENTS│   │ INVENTORY  │   │ BATTLE STATS │   │  SOCIAL   │
│  │ Plugin    │   │  Plugin    │   │   Plugin     │   │  Plugin   │
│  ├───────────┤   ├────────────┤   ├──────────────┤   ├───────────┤
│  │- unlock   │   │- addItem   │   │- addExp      │   │- follow   │
│  │- hasAchv  │   │- removeItem│   │- recordWin   │   │- updateBio│
│  │- getCount │   │- craftItem │   │- levelUp     │   │- getFollow│
│  │           │   │- inventory│   │- takeDamage  │   │- visitProf│
│  │(read/write│   │(read/write │   │(read/write   │   │(read/write│
│  │profile    │   │ profile    │   │ profile data)│   │profile    │
│  │ storage)  │   │ storage)   │   │             │   │storage)   │
│  └───────────┘   └────────────┘   └──────────────┘   └───────────┘
│
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow: Creating and Using a Profile

### Step 1: Profile Creation

```
User (0xAlice)
  │
  ├─ Calls: GameProfile.createProfile("Alice", "ipfs://avatar.png")
  │   │
  │   ├─ Validation: ProfileLib.validateProfileName("Alice")
  │   ├─ Validation: ProfileLib.validateAvatarURI("ipfs://...")
  │   │
  │   └─ Storage Updated:
  │      profiles[0xAlice] = {
  │          name: "Alice",
  │          avatarURI: "ipfs://avatar.png",
  │          createdAt: block.timestamp,
  │          exists: true
  │      }
  │
  └─ Event Emitted: ProfileCreated(0xAlice, "Alice", "ipfs://...")
```

### Step 2: Plugin Discovery and Enabling

```
User (0xAlice) wants achievements!
  │
  ├─ Discovers via: PluginStore.getOfficialPlugins()
  │   └─ Returns: [achievementsPlugin, inventoryPlugin, ...]
  │
  ├─ Deploys (or gets) AchievementsPlugin contract
  │
  ├─ Calls: GameProfile.enablePlugin(achievementsPlugin)
  │   │
  │   ├─ Validation: ProfileLib.validatePluginAddress(...)
  │   ├─ Verification: IPlugin(plugin).name() // Must implement interface
  │   │
  │   └─ Storage Updated:
  │      isPluginEnabled[0xAlice][achievementsPlugin] = true
  │      enabledPlugins[0xAlice].push(achievementsPlugin)
  │
  └─ Event Emitted: PluginEnabled(0xAlice, achievementsPlugin)
```

### Step 3: Plugin Execution via delegatecall

```
User (0xAlice) wants to unlock achievement!
  │
  ├─ Calls: GameProfile.executePluginFunction(
  │            achievementsPlugin,
  │            "unlockAchievement(string,string)",
  │            abi.encode("Boss Slayer", "Defeated final boss")
  │        )
  │
  └─ Inside GameProfile.executePluginFunction():
     │
     ├─ Check: isPluginEnabled[msg.sender][plugin] == true ✓
     │
     ├─ Prepare call: bytes4 selector = keccak256("unlockAchievement(string,string)")[0:4]
     ├─                bytes data = abi.encodePacked(selector, params)
     │
     ├─ DELEGATECALL: (success, result) = plugin.delegatecall(data)
     │   │
     │   └─ AchievementsPlugin.unlockAchievement() executes BUT:
     │      ├─ msg.sender = 0xAlice (PRESERVED!)
     │      ├─ address(this) = GameProfile (PRESERVED!)
     │      ├─ storage = GameProfile's storage (PRESERVED!)
     │      │
     │      └─ emit AchievementUnlocked(msg.sender, "Boss Slayer")
     │         Event appears in GameProfile's log ✓
     │
     ├─ Require: success == true
     │
     └─ Event Emitted: PluginCalled(0xAlice, achievementsPlugin, "unlockAchievement(...)")
```

## Component Relationship Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      LIBRARIES                               │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ProfileLib                    DelegatecallLib              │
│  ├─ validateProfileName        ├─ executeDelegatecall      │
│  ├─ validateAvatarURI          ├─ encodeCall               │
│  ├─ validatePluginAddress      ├─ getSelector              │
│  ├─ validateOwner              └─ Error handling           │
│  └─ Events & Errors                                         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
         ▲                              ▲
         │ imported by                  │ imported by
         │                              │
    ┌────┴──────────┐          ┌────────┴────────┐
    │               │          │                  │
    │         ┌─────▼────────┐ │  ┌──────────────▼─┐
    │         │  GameProfile │◄──┤   PluginStore   │
    │         │  (Core)      │ │  └──────────────┬─┘
    │         └─────┬────────┘ │                  │
    │               │          │                  │
    │               │ uses     │ manages          │
    │               │          │                  │
    │         ┌─────▼──────────────────────┐      │
    │         │  IPlugin (Interface)       │      │
    │         │  ├─ version()              │      │
    │         │  └─ name()                 │      │
    │         └─────▲──────────────────────┘      │
    │               │ implements                  │
    │               │                             │
    │   ┌───────────┼─────────────┬───────────────┤
    │   │           │             │               │
    │   ▼           ▼             ▼               ▼
    │┌─────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐
    ││ACHV │  │INVENTORY│  │ BATTLE  │  │ SOCIAL   │
    ││Plug │  │ Plugin  │  │ STATS   │  │ Plugin   │
    ││     │  │         │  │ Plugin  │  │          │
    │└─────┘  └─────────┘  └─────────┘  └──────────┘
    │
    │ (All plugins follow same pattern)
    │
    └─ All data stored in GameProfile
       All logic in individual plugins
       delegatecall is the bridge!
```

## Execution Context Visualization

### Context Layers

```
┌─────────────────────────────────────────────────────────────┐
│  ETHEREUM VIRTUAL MACHINE (EVM)                              │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Layer 3: Code Execution                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Which bytecode is being executed?                   │  │
│  │ - Call: Target contract's code                      │  │
│  │ - delegatecall: Target contract's code              │  │
│  │   (But storage belongs to caller!)                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
│  Layer 2: Storage Context                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Which storage is being read/written?                │  │
│  │ - Call: Target contract's storage                   │  │
│  │ - delegatecall: Caller's storage ⭐               │  │
│  │   (This is the key difference!)                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
│  Layer 1: Message Context                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Who called this, how much ETH?                      │  │
│  │ - msg.sender                                        │  │
│  │ - msg.value                                         │  │
│  │ - msg.data                                          │  │
│  │ delegatecall preserves all! ⭐                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Storage Layout

### Memory Map (Simplified)

```
GameProfile Storage Space:
┌───────────────────────────────────────────────────────────┐
│ SLOT 0: profiles mapping                                  │
│         mapping(address => Profile)                       │
├───────────────────────────────────────────────────────────┤
│ SLOT 1: enabledPlugins mapping                            │
│         mapping(address => address[])                     │
├───────────────────────────────────────────────────────────┤
│ SLOT 2: isPluginEnabled mapping                           │
│         mapping(address => mapping(address => bool))      │
├───────────────────────────────────────────────────────────┤
│ SLOT 3-6: Potential reserved slots                        │
├───────────────────────────────────────────────────────────┤
│                                                             │
│ SLOTS 100-150: AchievementsPlugin reserved                │
│                (When accessed via delegatecall)            │
├───────────────────────────────────────────────────────────┤
│ SLOTS 200-250: InventoryPlugin reserved                   │
├───────────────────────────────────────────────────────────┤
│ SLOTS 300-350: BattleStatsPlugin reserved                 │
├───────────────────────────────────────────────────────────┤
│ SLOTS 400-450: SocialPlugin reserved                      │
└───────────────────────────────────────────────────────────┘

KEY POINT:
- All data in ONE contract (GameProfile)
- Plugins don't have their own persistent storage
- Plugins use delegatecall to modify GameProfile storage
- Careful layout prevents collisions
```

## Transaction Flow: Complete Example

```
Transaction: Alice wants to record a battle win

User EOA (0xAlice)
  │
  └─ send transaction to GameProfile
     │
     ├─ Function: executePluginFunction(
     │    battleStatsPlugin,
     │    "recordWin(uint256)",
     │    abi.encode(1000)  // 1000 XP reward
     │ )
     │
     └─ tx.origin = 0xAlice
        msg.sender = 0xAlice
        msg.value = 0
        calldatasize = ...
        │
        ├─ GameProfile.executePluginFunction() EXECUTES
        │  │
        │  ├─ Check: isPluginEnabled[0xAlice][battleStatsPlugin] ✓
        │  │
        │  ├─ Encode: 
        │  │  selector = keccak256("recordWin(uint256)")[0:4]
        │  │  callData = abi.encodePacked(selector, abi.encode(1000))
        │  │
        │  ├─ Execute: (success, result) = battleStatsPlugin.delegatecall(callData)
        │  │  │
        │  │  ├─ DELEGATECALL STARTS
        │  │  │  ├─ Code location changes to: BattleStatsPlugin
        │  │  │  ├─ msg.sender stays: 0xAlice ✓
        │  │  │  ├─ Storage location stays: GameProfile ✓
        │  │  │  │
        │  │  │  ├─ BattleStatsPlugin.recordWin(1000) executes:
        │  │  │  │  │
        │  │  │  │  ├─ Updates player stats (reads from GameProfile storage)
        │  │  │  │  │
        │  │  │  │  ├─ Increments wins counter (writes to GameProfile storage)
        │  │  │  │  │
        │  │  │  │  ├─ Adds experience (writes to GameProfile storage)
        │  │  │  │  │
        │  │  │  │  └─ emit BattleResultRecorded(msg.sender=0xAlice, won=true)
        │  │  │  │     └─ Event logged in GameProfile's event log ✓
        │  │  │  │
        │  │  │  └─ Return to GameProfile
        │  │  │
        │  │  └─ DELEGATECALL ENDS
        │  │     success = true ✓
        │  │
        │  ├─ Require: success == true ✓
        │  │
        │  └─ emit PluginCalled(0xAlice, battleStatsPlugin, "recordWin(uint256)")
        │
        ├─ Transaction succeeds
        │
        └─ Effects:
           - GameProfile storage updated with new stats
           - Events emitted: BattleResultRecorded, PluginCalled
           - Alice's profile now has updated battle stats
           - All data persists in GameProfile
```

## System Benefits Visualization

```
┌─────────────────────────────────────────────────────────┐
│  TRADITIONAL MONOLITHIC APP                              │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │        SINGLE HUGE CONTRACT                        │ │
│  │                                                    │ │
│  │  - Core profile logic                             │ │
│  │  - Achievement logic                              │ │
│  │  - Inventory logic                                │ │
│  │  - Battle stats logic                             │ │
│  │  - Social logic                                   │ │
│  │  - ALL in one place ❌                            │ │
│  │                                                    │ │
│  │  Problems:                                         │ │
│  │  ❌ Huge bytecode                                  │ │
│  │  ❌ Hard to upgrade                                │ │
│  │  ❌ One bug breaks everything                      │ │
│  │  ❌ Difficult to maintain                          │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
└─────────────────────────────────────────────────────────┘

VS

┌─────────────────────────────────────────────────────────┐
│  OUR MODULAR PLUGIN SYSTEM                               │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │GameProfile   │  │PluginStore   │                     │
│  │(Lightweight) │  │(Registry)    │                     │
│  └──────────────┘  └──────────────┘                     │
│        ▲                 ▲                                │
│        │ delegates       │ manages                        │
│        ▼                 ▼                                │
│  ┌──────────────────────────────────────────────────┐   │
│  │ PLUGINS (can be enabled/disabled independently)  │   │
│  │  ✓ Achievements    ✓ Battle Stats                │   │
│  │  ✓ Inventory       ✓ Social                      │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
│  Benefits:                                               │
│  ✓ Small core contract                                   │
│  ✓ Easy to upgrade plugins                               │
│  ✓ One plugin fails, others work                         │
│  ✓ Easy to maintain and extend                           │
│  ✓ Only pay gas for features used                        │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## delegatecall Magic Explained

```
THE PARADOX:
  Run code from Plugin          BUT keep data in Profile
         ▼                                      ▼
  │---────────────────────────────────────────────────────│
  │           DELEGATECALL SOLVES THIS!                   │
  │---────────────────────────────────────────────────────│

HOW IT WORKS:
  Normal Call:
    Plugin.code ────────→ executed
    Plugin.storage ─────→ data location
    Caller.sender ──────→ changed to Plugin

  delegatecall:
    Plugin.code ────────→ executed ✓
    Profile.storage ────→ data location ✓
    Caller.sender ──────→ unchanged ✓

THE RESULT:
  ├─ Code executes from Plugin
  ├─ Data stored in Profile
  ├─ Caller identity preserved
  └─ Perfect for modular architecture!
```

## Comparison: Different Call Types

```
┌────────────┬─────────────┬──────────────┬────────────────────┐
│ Call Type  │ Code From   │ Storage In   │ msg.sender Becomes │
├────────────┼─────────────┼──────────────┼────────────────────┤
│ call       │ Target      │ Target       │ This contract      │
│            │ (external)  │ (external)   │                    │
├────────────┼─────────────┼──────────────┼────────────────────┤
│staticcall  │ Target      │ Target       │ This contract      │
│            │ (read only) │ (can't write)│ (can't modify)     │
├────────────┼─────────────┼──────────────┼────────────────────┤
│delegatecall│ Target      │ This         │ Original caller ✓  │
│            │ (external)  │ (this contract)│                  │
├────────────┼─────────────┼──────────────┼────────────────────┤
│callcode    │ Target      │ This         │ This (deprecated)  │
│            │ (deprecated)│ (this contract)│                  │
└────────────┴─────────────┴──────────────┴────────────────────┘

⭐ = delegatecall is unique!
```

This modular architecture is what powers modern Web3 gaming and DeFi systems!
