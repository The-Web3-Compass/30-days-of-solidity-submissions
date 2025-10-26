// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {

     struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping (address => PlayerProfile) public profiles;

    // 插件名称 -》 插件地址
    mapping (string => address) public pluginMap;

    function setPlayerProfile(string memory _name , string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name , _avatar);
    }

    
    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    function registerPlugin(string memory key, address pluginAddress) external {
        pluginMap[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return pluginMap[key];
    }

    function runPlugins(string memory _pluginName , string memory functionSignature, address user , string memory argument) external {
        address pluginAddr = pluginMap[_pluginName];
        require(pluginAddr != address(0), "not  set");

        bytes memory data = abi.encodeWithSignature(functionSignature, user ,argument);
        (bool success , ) = pluginAddr.call(data);
        require(success , "Plugin execution failed");
    }

    // 通过staticcall 实现不同渠道
    function runPluginView(string memory _pluginName , string memory functionSignature, address user ) external view returns (string memory) {
        address pluginAddr = pluginMap[_pluginName];
        require(pluginAddr != address(0), "not  set");
        
        bytes memory data = abi.encodeWithSignature(functionSignature , user);
        (bool success, bytes memory result) = pluginAddr.staticcall(data);

        require( success , "Plugin view call failed");

        return abi.decode(result,(string));

    }

}