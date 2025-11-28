//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract PlusinStore{
    struct PlayerProfile{
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) players;

    mapping(string => address) plugins;  //插件注册表

    function setProfile(string memory _name, string memory _avatar)  external{
        players[msg.sender] = PlayerProfile({name:_name, avatar:_avatar});
    }

   function getProfile() view external returns(string memory,string memory){
        return(players[msg.sender].name,players[msg.sender].avatar);
    }

    function deployPlugin(string memory pluginKey,address pluginAdr) external{
        plugins[pluginKey] = pluginAdr;
    }

    function getPlugin(string memory pluginKey) view external returns(address){
        return plugins[pluginKey];
    }

    function runPlugin(string memory pluginKey,address user,string memory functionSignature,string memory argument) external{
        require(plugins[pluginKey] != address(0),"plugin not exist");
        bytes memory data = abi.encodeWithSignature(functionSignature,user,argument);
        (bool success,) = plugins[pluginKey].call(data);
        require(success,"call failed");
    }

    function checkRunPlugin(string memory pluginKey,address user,string memory functionSignature) external view returns(string memory){
        require(plugins[pluginKey] != address(0),"plugin not exist");
        bytes memory data = abi.encodeWithSignature(functionSignature,user);
        (bool success, bytes memory res) = plugins[pluginKey].staticcall(data);
        require(success,"call failed");
        return abi.decode(res,(string));
    }





}