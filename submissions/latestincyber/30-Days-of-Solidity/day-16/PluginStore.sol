// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    function registerPlugin(string memory key, address pluginAddress) external onlyOwner {
        require(pluginAddress != address(0), "Invalid plugin address");
                require(pluginAddress.code.length > 0, "Plugin must be a contract");
                plugins[key] = pluginAddress;
    }

    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];
                require(plugin != address(0), "Plugin not found");
                require(msg.sender == user, "Can only run plugin for self");

        // this is where (in a real system) we might want to verify who is calling/restrict calls

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success, ) = plugin.call(data);
        require(success, "Plugin call failed");
    }

    function runPluginView(
        string memory key,
        string memory functionSignture,
        address user
    ) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address (0), "Plugin not found");

        bytes memory data = abi.encodeWithSignature(functionSignture, user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");
        return abi.decode(result, (string));
    }
}