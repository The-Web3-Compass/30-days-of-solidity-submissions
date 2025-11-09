// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PluginStore{
    struct PlayerProfile{
        string name;
        string avatar;
    }
    mapping (address => PlayerProfile) public profiles;
    mapping (string => address)public plugins;

    function setProfiles(string memory _name,string memory _avatar)external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }
    function getProfiles(address _player)external view returns(string memory,string memory){
        return (profiles[_player].name,profiles[_player].avatar);
    }

    function registerPlugin(string memory _key,address pluginAddress)external {
        plugins[_key] = pluginAddress;
    }

    function getPlugin(string memory _key)external view returns(address){
        return plugins[_key];
    }

    function runPlugin(string memory key,string memory functionSignature,address user,string memory argument)external {
        address plugin = plugins[key];
         require(plugin != address(0), "Plugin not registered");

         bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
         (bool success,) = plugin.call(data);
         require(success, "Plugin execution failed");
    }

    function runPluginView(string memory key,string memory functionSignature,address user)external view returns (string memory){
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data);

        require(success, "Plugin view call failed");

        return abi.decode(result, (string));
    }
}