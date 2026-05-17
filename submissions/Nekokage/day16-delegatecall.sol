// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimplePluginStore {
    
    struct UserProfile {
        string name;
        string avatar;
    }
    
    mapping(address => UserProfile) public profiles;
    mapping(string => address) public plugins;
    
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = UserProfile(_name, _avatar);
    }
    
    function getProfile(address user) external view returns (string memory, string memory) {
        UserProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }
    
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }
    
    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }
    
    function runPlugin(string memory key, string memory functionName, string memory argument) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not found");
        
        bytes memory data = abi.encodeWithSignature(functionName, msg.sender, argument);
        (bool success, ) = plugin.call(data);
        require(success, "Plugin call failed");
    }
    
    function runPluginView(string memory key, string memory functionName) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not found");
        
        bytes memory data = abi.encodeWithSignature(functionName, msg.sender);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");
        
        return abi.decode(result, (string));
    }
}