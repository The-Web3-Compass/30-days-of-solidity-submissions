// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {
    struct PlayerProfile{
        string name;//Can use bytes32 for gas saving?
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;//plugins mapping to specific deployed contract addresses
    // ========== Core Profile Logic ==========
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address _user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[_user];
        return (profile.name, profile.avatar);
    }
    // ========== Plugin Management ==========
    function registerPlugin (string memory _key, address _pluginAddress) external {
        plugins[_key] = _pluginAddress;
    }

    function getPlugin(string memory _key) external view returns (address) {
        return plugins[_key];
    }
    // ========== Plugin Execution ==========
    function runPlugin(
        string memory _key,
        string memory _functionSignature,
        address _user,
        string memory _argument
    ) external {
        address plugin = plugins[_key];
        require(plugin != address(0), "Plugin not registered");
        bytes memory data = abi.encodeWithSignature(_functionSignature, _user, _argument);
        (bool success, ) = plugin.call(data);
        require(success, "Plugin execution failed");
    }

    function runPluginView(
        string memory _key,
        string memory _functionSignature,
        address _user
    ) external view returns (string memory) {
        address plugin = plugins[_key];
        require(plugin != address(0), "Plugin not registered");
        bytes memory data = abi.encodeWithSignature(_functionSignature, _user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");
        return abi.decode(result, (string));
    }
}
