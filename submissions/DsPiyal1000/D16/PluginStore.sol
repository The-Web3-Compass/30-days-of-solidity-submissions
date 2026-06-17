// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;
    address public owner;
    bool private locked;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier noReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    function setProfile(string calldata _name, string calldata _avatar) external {
        require(bytes(_name).length > 0, "Empty name");
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    function registerPlugin(string calldata key, address pluginAddress) external onlyOwner {
        require(pluginAddress != address(0), "Invalid plugin address");
        require(bytes(key).length > 0, "Empty key");
        plugins[key] = pluginAddress;
    }

    function getPlugin(string calldata key) external view returns (address) {
        return plugins[key];
    }

    function runPlugin(
        string calldata key,
        string calldata functionSignature,
        bytes calldata arguments
    ) external noReentrant {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");
        require(bytes(functionSignature).length > 0, "Empty signature");
        
        bytes4 selector = bytes4(keccak256(bytes(functionSignature)));
        bytes memory payload = abi.encodePacked(selector, arguments);
        (bool success, ) = plugin.call(payload);
        require(success, "Plugin execution failed");
    }

    function runPluginView(
        string calldata key,
        string calldata functionSignature,
        bytes calldata arguments
    ) external view returns (bytes memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");
        require(bytes(functionSignature).length > 0, "Empty signature");
        
        bytes4 selector = bytes4(keccak256(bytes(functionSignature)));
        bytes memory payload = abi.encodePacked(selector, arguments);
        (bool success, bytes memory result) = plugin.staticcall(payload);
        require(success, "View execution failed");
        return result;
    }
}