// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
        mapping(address => bool) activePlugins;
    }

    mapping(address => PlayerProfile) public profiles;
    
    event PluginActivated(address indexed player, address indexed plugin);
    event PluginExecuted(address indexed player, address indexed plugin, bytes4 functionSelector);
    event ProfileUpdated(address indexed player);

    function activatePlugin(address plugin) external {
        require(!profiles[msg.sender].activePlugins[plugin], "Plugin already active");
        profiles[msg.sender].activePlugins[plugin] = true;
        emit PluginActivated(msg.sender, plugin);
    }

    function executePlugin(address plugin, bytes calldata data) external returns (bytes memory) {
        require(profiles[msg.sender].activePlugins[plugin], "Plugin not activated");
        
        bytes4 functionSelector = bytes4(data[:4]);
        (bool success, bytes memory result) = plugin.delegatecall(data);
        require(success, "Plugin execution failed");
        
        emit PluginExecuted(msg.sender, plugin, functionSelector);
        return result;
    }

    function updateProfile(string calldata name, string calldata avatar) external {
        PlayerProfile storage profile = profiles[msg.sender];
        profile.name = name;
        profile.avatar = avatar;
        emit ProfileUpdated(msg.sender);
    }

    function getProfile(address player) external view returns (string memory name, string memory avatar) {
        PlayerProfile storage profile = profiles[player];
        return (profile.name, profile.avatar);
    }

    function isPluginActive(address player, address plugin) external view returns (bool) {
        return profiles[player].activePlugins[plugin];
    }
}
