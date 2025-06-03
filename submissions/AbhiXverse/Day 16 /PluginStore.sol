// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract PluginStore {

    // struct to store player profile
    struct PlayerProfile{
        string name;
        string avatar;
    }

    // mapping to store player profile
    // mapping to store plugin address
    mapping (address => PlayerProfile) public profiles;
    mapping (string => address) public plugins;

    // function to set player profile
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    } 

    // function to get player profile
    function getProfile(address user) external view returns(string memory, string memory) {
        PlayerProfile memory profile = profiles[user];                  // get player profile
        return (profile.name, profile.avatar);
    }

    // function to set plugin details 
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }


    // function to get plugin details 
    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // function to run plugin
    function runPlugin(string memory key, string memory functionSignature, address user, string memory argument) external {
        address plugin = plugins[key];                                                   // get plugin address
        require(plugin != address(0), "No plugin found");                                // check if plugin address is valid
        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);  // encode function signature and arguments
        (bool success,) = plugin.call(data);                                             // call plugin function
        require (success, "plugin execution failed");                                    // check if plugin execution was successful
    }

    // function to get plugin 
    function runPluginView(string memory key, string memory functionSignature, address user) external view returns (string memory) {
        address plugin = plugins[key];                                                   // get plugin address
        require (plugin != address(0), "No plgin found");                                // check if plugin address is valid
        bytes memory data = abi.encodeWithSignature(functionSignature, user);            // encode function signature and user address
        (bool success, bytes memory result) = plugin.staticcall(data);                   // call plugin function
        require(success, "plugin execution failed");                                     // check if plugin execution was successful
        return abi.decode(result,(string));                                              // decode result
    }
}


