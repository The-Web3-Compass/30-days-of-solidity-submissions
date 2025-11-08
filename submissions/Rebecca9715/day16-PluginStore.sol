// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {
    // 记录玩家的信息
    struct PlayerProfile {
        string name;
        string avatar;
    }
    // 地址和玩家信息的map
    mapping(address => PlayerProfile) public profiles;

    // === Multi-plugin support ===
    mapping(string => address) public plugins;

    // ========== Core Profile Logic ==========
    // 记录玩家信息
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // ========== Plugin Management ==========
    // 注册插件，key是什么？
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // ========== Plugin Execution ==========
    // 外接插件
function runPlugin(
    string memory key,
    string memory functionSignature,
    address user,
    string memory argument
) external {
    address plugin = plugins[key];
    require(plugin != address(0), "Plugin not registered");

    bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
    (bool success, ) = plugin.call(data);
    require(success, "Plugin execution failed");
}

function runPluginView(
    string memory key,
    string memory functionSignature,
    address user
) external view returns (string memory) {
    address plugin = plugins[key];
    require(plugin != address(0), "Plugin not registered");

    bytes memory data = abi.encodeWithSignature(functionSignature, user);
    (bool success, bytes memory result) = plugin.staticcall(data);
    require(success, "Plugin view call failed");

    return abi.decode(result, (string));
}

}

// pluginStore.runPlugin(
//   "achieve",
//   "setAchievement(address,string)",
//   msg.sender,
//   "victory"
// );


// pluginStore.runPlugin(
//   "weapon",
//   "setWeapon(address,string)",
//   msg.sender,
//   "Golden Axe"
// );

// pluginStore.runPluginView(
//   "weapon",
//   "getWeapon(address)",
//   userAddress
// );

// day16
// 1. 三个合约都部署起来，在store合约下注册插件，不需要导入，注册插件的时候写入地址即可
// 2. runplugin的时候将上面的信息记录下来，set之后可以get