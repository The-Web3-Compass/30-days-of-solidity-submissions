// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
- **The PluginStore handles access control** 
— this function is intentionally left open so the plugin can be reused anywhere.
- We use a standard setter pattern so the PluginStore can delegate calls to it.
*/
contract PluginStore {

    struct PlayerProfile {
        string name;
        string avatar;//头像居然是string...?应该是图片链接吧
    }

    mapping(address => PlayerProfile) public profiles;

    // === Multi-plugin support ===
    mapping(string => address) public plugins;//contract addresses

    // ========== Core Profile Logic ==========

    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // ========== Plugin Management ==========

    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // ========== Plugin Execution ==========
function runPlugin(
    string memory key,
    string memory functionSignature,//functionSignature=函数名
    address user,
    string memory argument
) external {
    address plugin = plugins[key];
    require(plugin != address(0), "Plugin not registered");

    bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
    (bool success, ) = plugin.call(data);//call the address of the plugin contract
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
