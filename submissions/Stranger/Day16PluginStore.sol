// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract pluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    // 定义2个映射: 玩家地址 -> 玩家信息, 插件名称 -> 插件地址
    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;

    // 设置个人信息
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    // 查询个人信息
    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // 注册插件
    function registerPlugin(string memory _key, address _pluginAddress) external {
        plugins[_key] = _pluginAddress;
    }

    // 查询插件地址
    function getPlugin(string memory _key) external view returns (address) {
        return plugins[_key];
    }

    // 运行插件, 给functionSignature传参时参数间不能有空格
    function runPlugin(string memory key, string memory functionSignature, address user, string memory argument) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success, ) = plugin.call(data);
        require(success, "Plugin execution failed");
    }

    // 运行插件(只读)
    function runPluginView(string memory key, string memory functionSignature, address user) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");
        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin execution failed");
        return abi.decode(result, (string));
    }
}