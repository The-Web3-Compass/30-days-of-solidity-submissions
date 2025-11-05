// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PluginStore
 * @dev 核心资料管理 + 插件注册与调用系统
 *      - 存储玩家基本资料（名字、头像）
 *      - 注册各类功能插件（成就、武器、社交等）
 *      - 动态调用插件逻辑，实现模块化扩展
 */
contract PluginStore {
    // ======= 玩家基本资料 =======
    struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;

    // ======= 插件注册表（key -> plugin address）=======
    mapping(string => address) public plugins;

    // ========== 基本资料功能 ==========
    /// @notice 设置个人资料
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    /// @notice 获取玩家资料
    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // ========== 插件管理 ==========
    /// @notice 注册插件
    /// @param key 插件标识符，如 "achievement" 或 "weapon"
    /// @param pluginAddress 插件合约地址
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    /// @notice 查询插件地址
    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // ========== 插件执行（写操作）==========
    /// @notice 执行插件函数（允许状态修改）
    /// @param key 插件标识符
    /// @param functionSignature 函数字符串，如 "setWeapon(address,string)"
    /// @param user 用户地址
    /// @param argument 参数字符串（例如武器名或成就名）
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

    // ========== 插件执行（读操作）==========
    /// @notice 执行插件的只读函数
    /// @param key 插件标识符
    /// @param functionSignature 函数字符串，如 "getWeapon(address)"
    /// @param user 用户地址
    /// @return 返回插件的字符串结果
    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    ) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");

        return abi.decode(result, (string));
    }
}