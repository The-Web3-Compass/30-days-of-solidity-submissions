### Day 16 - PluginStore

#### Task Overview

In this task, we are building a modular smart contract system where multiple external plugins can be registered and executed dynamically using delegatecall. This allows us to extend the core contract’s functionality without modifying its source code.

#### Prerequisites

* Foundry installed and configured
* Basic understanding of delegatecall and modular contract design
* Solidity ^0.8.13

#### Contracts Explanation

1. **PluginStore.sol** – The core contract responsible for registering plugin contracts by name and executing them through delegatecall.
2. **AchievementPlugin.sol** – A plugin contract that manages achievements for users.
3. **BattleStatsPlugin.sol** – A plugin contract that tracks and manages player battle statistics.

#### Foundry Commands

```bash
forge build
forge test
```

#### Deployment and Execution Commands

```bash
# Deploy contracts
forge create src/PluginStore.sol:PluginStore --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
forge create src/AchievementPlugin.sol:AchievementPlugin --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
forge create src/BattleStatsPlugin.sol:BattleStatsPlugin --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>

# Register plugin
cast send <PluginStore_Address> "registerPlugin(string,address)" "Achievement" <AchievementPlugin_Address> \
--rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>

# Execute a plugin via delegatecall
cast send <PluginStore_Address> "executePlugin(string,bytes)" "Achievement" \
$(cast abi-encode "addAchievement(address,uint256)" <YOUR_ADDRESS> 5) \
--rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
```

# End of the Project.
