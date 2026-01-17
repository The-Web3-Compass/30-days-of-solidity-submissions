// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PluginStore {
    struct Player {
        string name;
        string avatar;
        mapping(bytes32 => uint256) pluginData;
    }

    mapping(address => Player) private players;
    mapping(bytes4 => address) private pluginRegistry;

    event PluginRegistered(bytes4 indexed selector, address plugin);
    event PluginExecuted(address indexed player, address plugin, bytes4 selector);

    function setProfile(string calldata name, string calldata avatar) external {
        Player storage player = players[msg.sender];
        player.name = name;
        player.avatar = avatar;
    }

    function getProfile(address playerAddress) external view returns (string memory, string memory) {
        Player storage player = players[playerAddress];
        return (player.name, player.avatar);
    }

    function registerPlugin(bytes4 selector, address plugin) external {
        require(plugin != address(0), "Invalid plugin address");
        pluginRegistry[selector] = plugin;
        emit PluginRegistered(selector, plugin);
    }

    function executePlugin(bytes calldata data) external {
        require(data.length >= 4, "Invalid data");
        bytes4 selector;
        assembly {
            selector := calldataload(data.offset)
        }
        address plugin = pluginRegistry[selector];
        require(plugin != address(0), "Plugin not registered");
        (bool success, ) = plugin.delegatecall(data);
        require(success, "Plugin execution failed");
        emit PluginExecuted(msg.sender, plugin, selector);
    }

    function getPluginData(bytes32 key) external view returns (uint256) {
        return players[msg.sender].pluginData[key];
    }

    function _setPluginData(address player, bytes32 key, uint256 value) internal {
        players[player].pluginData[key] = value;
    }
}

contract AchievementsPlugin {
    function addAchievement(bytes32 achievementId, uint256 points) external {
        PluginStore store = PluginStore(address(this));
        store._setPluginData(msg.sender, achievementId, points);
    }

    function getAchievement(bytes32 achievementId) external view returns (uint256) {
        PluginStore store = PluginStore(address(this));
        return store.getPluginData(achievementId);
    }
}
