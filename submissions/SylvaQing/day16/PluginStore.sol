// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore{
    // 基本信息
    struct PlayerProfile{
        string name;
        string avatar;
    }

    //个人资料
    mapping(address=>PlayerProfile) public profiles;
    // 使用这个映射来通过字符串键（如 "achievements" 或 "weapons"）注册插件
    mapping(string=>address)public plugins ;

    //设置获取个人信息与插件
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    //插件运行
    function runPlugin(
        string memory key,
        string memory functionSignnature,
        address user,
        string memory argument
    )external {
        address plugin = plugins[key]; //用key找地址
        require(plugin!=address(0),"Plugin not registered");

        bytes memory data=abi.encodeWithSignature(functionSignnature, user,argument);
        (bool success,)=plugin.call(data);
        require(success,"Plugin execution failed");
    }

    // 高效且无风险地获取插件数据
    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    )external view returns (string memory){
        address plugin=plugins[key];
        require(plugin!=address(0),"Plugin not registered");

        bytes memory data=abi.encodeWithSignature(functionSignature, user);
        (bool success,bytes memory result)=plugin.staticcall(data);
        require(success,"Plugin view call failed");

        return  abi.decode(result,(string));
        
    }


}