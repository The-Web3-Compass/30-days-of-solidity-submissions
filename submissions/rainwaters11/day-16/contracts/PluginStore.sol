// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) private playerProfiles;
    mapping(string => address) public plugins;

    event ProfileUpdated(address indexed player, string name, string avatar);
    event PluginRegistered(string indexed key, address indexed plugin);
    event PluginRun(address indexed plugin, string functionSignature, bool success, bytes result);
    event PluginViewRun(address indexed plugin, string functionSignature, bool success, bytes result);

    error PluginCallFailed(bytes reason);
    error PluginViewCallFailed(bytes reason);
    error PluginNotRegistered(string key);

    function setProfile(string calldata name, string calldata avatar) external {
        playerProfiles[msg.sender] = PlayerProfile({name: name, avatar: avatar});
        emit ProfileUpdated(msg.sender, name, avatar);
    }

    function getProfile(address player) external view returns (PlayerProfile memory) {
        return playerProfiles[player];
    }

    function registerPlugin(string calldata key, address plugin) external {
        require(plugins[key] == address(0), "Plugin key already registered");
        plugins[key] = plugin;
        emit PluginRegistered(key, plugin);
    }

    // Executes plugin logic with one address and one string argument.
    // Example signature: "setBadge(address,string)"
    function runPlugin(
        address plugin,
        string calldata functionSignature,
        address user,
        string calldata value
    ) external returns (bytes memory result) {
        require(plugin.code.length > 0, "Plugin has no code");
        bytes memory data = abi.encodeWithSignature(functionSignature, user, value);
        (bool success, bytes memory returnData) = plugin.call(data);

        emit PluginRun(plugin, functionSignature, success, returnData);

        if (!success) revert PluginCallFailed(returnData);
        return returnData;
    }

    // Safely reads plugin data via staticcall.
    // Example signature: "getBadge(address)"
    function runPluginView(
        address plugin,
        string calldata functionSignature,
        address user
    ) external view returns (bytes memory result) {
        require(plugin.code.length > 0, "Plugin has no code");
        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory returnData) = plugin.staticcall(data);

        if (!success) revert PluginViewCallFailed(returnData);
        return returnData;
    }

    // Key-based read. Reverts with PluginNotRegistered when the key has never been registered.
    function runPluginViewByKey(
        string calldata key,
        string calldata functionSignature,
        address user
    ) external view returns (bytes memory result) {
        address plugin = plugins[key];
        if (plugin == address(0)) revert PluginNotRegistered(key);
        require(plugin.code.length > 0, "Plugin has no code");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory returnData) = plugin.staticcall(data);

        if (!success) revert PluginViewCallFailed(returnData);
        return returnData;
    }
}
