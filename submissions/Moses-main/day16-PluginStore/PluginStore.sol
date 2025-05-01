// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Build a modular profile system for a Web3 game. 
// The core contract stores each player's basic 
// profile (like name and avatar), but players 
// can activate optional 'plugins' to add extra features 
// like achievements, inventory management, battle stats, or 
// social interactions. Each plugin is a separate 
// contract with its own logic, and the main 
// contract uses delegatecall to execute plugin functions 
// while keeping all data in the core profile. 
// This allows developers to add or upgrade features 
// without redeploying the main contract—just like 
// installing new add-ons in a game. 
// You'll learn how to use delegatecall safely, 
// manage execution context, and organize external 
// logic in a modular way.


contract PluginStore {

    struct PlayerProfile{
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;

    // multi-plugin support
    mapping(string => address) public plugins;

    // core Profile Logic
    function setProfile(string memory _name, string memory _avatar) external{
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }


    function getProfile(address user) external view returns(string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }


    // Pluggin Management
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns(address) {
        return plugins[key];
    }

    // Plugin execution
    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success,) = plugin.call(data);
        require(success, "Plugin execution failed");
    }


    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    ) external view returns(string memory){
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");

        return abi.decode(result, (string));
    }
}