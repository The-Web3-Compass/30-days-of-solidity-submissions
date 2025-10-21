//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract PluginStore{

    struct PlayerProfile{
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;

    function SetProfile(string memory _name, string memory _avatar) external{
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function GetProfile(address user) external view returns(string memory, string memory){
        PlayerProfile memory profile = profiles[user];
        return(profile.name, profile.avatar);
    }

    function RegisterPlugin(string memory key, address PluginAddress) external{
        plugins[key] = PluginAddress;
    }

    function GetPlugin(string memory key) external view returns(address){
        return plugins[key];
    }

    function RunPlugin(string memory key, string memory functionSignature, address user, string memory argument) external{
        address plugin = plugins[key];
        require(plugin != address(0), "No plugin found");
        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success,) = plugin.call(data);
        require(success, "Plugin execution failed");
    }

    function RunPluginView(string memory key, string memory functionSignature, address user) external view returns(string memory){
        address plugin = plugins[key];
        require(plugin != address(0), "No plugin found");
        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin execution failed");
        return abi.decode(result, (string)); 
    }

}
