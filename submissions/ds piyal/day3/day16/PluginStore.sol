// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;

    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    function registerPlugin(string memory key, address pluginAddress) external {
        require(pluginAddress != address(0), "Invalid plugin address");
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    function runPlugin(
        string memory key,
        string memory functionSignature,
        bytes memory arguments
    ) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes4 selector = bytes4(keccak256(bytes(functionSignature)));
        bytes memory payload = abi.encodePacked(selector, arguments);
        (bool success, ) = plugin.call(payload);
        require(success, "Plugin execution failed");
    }

    function runPluginView(
        string memory key,
        string memory functionSignature,
        bytes memory arguments
    ) external view returns (bytes memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes4 selector = bytes4(keccak256(bytes(functionSignature)));
        bytes memory payload = abi.encodePacked(selector, arguments);
        (bool success, bytes memory result) = plugin.staticcall(payload);
        require(success, "View execution failed");
        return result;
    }
}
