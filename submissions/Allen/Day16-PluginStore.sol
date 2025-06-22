// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PluginStore{
    /**
    - `call` — to trigger state changes in external contracts
    - `delegatecall` — when we want plugin logic but to **store data inside the main contract**
    - `staticcall` — for efficient, read-only queries
    */
    
    struct playerProfile{
        string name;
        string avatarUrl;
    }

    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;

    
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {
        require(profiles[user] != 0,"User doesn't exit");
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    function registerPlugin(string memory key, address pluginAddress) external {
        require(pluginAddress   != address(0),"Invaild address");
        require(bytes(key).length != 0,"Invalid key");
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        require(bytes(key).length != 0,"Invalid key");
        return plugins[key];
    }


    function runPlugin(string memory key,string memory functionSignature,
    address user,string memory argument) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        // The plugin executes in its own storage context, not the PluginStore's.
        (bool success, ) = plugin.call(data);
        require(success, "Plugin execution failed");

    }

    function runPluginView(string memory key,string memory functionSignature,address user) 
    external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        // It’s read-only
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");

        return abi.decode(result, (string));
    }





}