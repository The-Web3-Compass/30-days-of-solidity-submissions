//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract PluginStore{

    //结构体，类似于 自定义数据类型
    struct playerProfile{
        string name;
        string avatar;
    }

    mapping(address => playerProfile) public profiles;

//使用此映射通过字符串键（如 “成就” 或 “武器” ）注册插件，并将它们映射到已部署的合约地址
    mapping(string => address) public plugins;

//设置并返回个人资料
    function setProfile(string memory _name,string memory _avatar) external {
        profiles[msg.sender] = playerProfile(_name,_avatar);
    }

    function getProfile(address user) external view returns(string memory,string memory){
        playerProfile memory profile = profiles[user];
        return(profile.name,profile.avatar);
    }

//注册与获取插件
    function registerPlugin(string memory key,address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns(address){
        return plugins[key];
    }


    function runPlugin(
        address user,
        string memory key,
        string memory functionSignature,
        string memory argument   
    ) external {
        address plugin = plugins[key]; //address plugin 已登记的合约地址
        require(plugin != address(0),"Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success, ) = plugin.call(data);
        require(success, "Plugin execution failed");
    }

    function runPluginView(
        address user,
        string memory key,
        string memory functionSignature
    ) external view returns (string memory){
        address plugin = plugins[key]; 
        require(plugin != address(0),"Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success,bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");

        return abi.decode(result,(string));  //(……)元组括号，用来指定解码结构
    }

}
