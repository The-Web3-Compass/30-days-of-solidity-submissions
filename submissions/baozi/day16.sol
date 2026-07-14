// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PluginStore - A modular plugin runner and profile registry
contract PluginStore {

    // --------------------- Structs ---------------------

    struct PlayerProfile {
        string name;
        string avatar;
    }

    // --------------------- Storage ---------------------

    // 用户地址 => 用户信息
    mapping(address => PlayerProfile) public profiles;

    // 插件键名 => 插件合约地址
    mapping(string => address) public plugins;

    // --------------------- Profile ---------------------

    /// @notice 设置当前用户的 profile（姓名 + 头像）
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    /// @notice 获取某用户的 profile
    function getProfile(address user) external view returns (string memory name, string memory avatar) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // --------------------- Plugin Management ---------------------

    /// @notice 注册插件合约
    function registerPlugin(string memory key, address pluginAddress) external {
        require(pluginAddress != address(0), "Invalid plugin address");
        plugins[key] = pluginAddress;
    }

    /// @notice 获取插件合约地址
    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // --------------------- Plugin Execution ---------------------

    /// @notice 执行插件的非视图函数
    /// @param key 插件键名，如 "weapon"
    /// @param functionSignature 插件方法签名，如 "setWeapon(address,string)"
    /// @param user 调用目标用户地址
    /// @param argument 插件方法参数（string 类型）
    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success, ) = plugin.call(data);
        require(success, "Plugin execution failed");
    }

    /// @notice 执行插件的视图函数，返回字符串结果
    /// @param key 插件键名
    /// @param functionSignature 插件方法签名，如 "getWeapon(address)"
    /// @param user 要查询的用户地址
    /// @return result 插件返回的字符串
    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    ) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin execution failed");

        return abi.decode(result, (string));
    }
}
