// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore{
    struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;

    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns(string memory, string memory) {
        require(user != address(0), "Invalid address");
        return(profiles[user].name, profiles[user].avatar);
    }

    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns(address){
        return plugins[key];
    }

    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user, 
        string memory argument
    ) external {
        require(plugins[key] != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success, ) = plugins[key].call(data);
        require(success, "Plugin execution failed");
    }

     function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
     ) public view returns(string memory) {
        require(plugins[key] != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugins[key].staticcall(data);
        require(success, "Plugin view call failed");

         return abi.decode(result, (string));
    }
}
