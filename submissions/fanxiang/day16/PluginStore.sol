// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PluginStore
 * @dev 模块化玩家档案核心合约，支持基础档案管理与插件注册、调用
 * 插件通过 call/staticcall 实现状态变更与只读查询，保持核心轻量化
 */
contract PluginStore {
    // 玩家基础档案结构：仅存储核心信息（姓名+头像）
    struct PlayerProfile {
        string name;    // 玩家昵称
        string avatar;  // 头像链接/标识
    }

    // 玩家地址 → 基础档案映射
    mapping(address => PlayerProfile) public profiles;

    // 插件标识 → 插件合约地址映射（注册插件用）
    mapping(string => address) public plugins;

    // ========== 基础档案操作 ==========
    /**
     * @dev 玩家设置/更新自身基础档案
     * @param _name 新昵称
     * @param _avatar 新头像链接/标识
     */
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    /**
     * @dev 查询指定玩家的基础档案
     * @param user 目标玩家地址
     * @return name 昵称，avatar 头像
     */
    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // ========== 插件管理 ==========
    /**
     * @dev 注册插件（需确保插件合约已部署）
     * @param key 插件唯一标识（如"achievements"/"weapons"）
     * @param pluginAddress 插件合约部署地址
     */
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    /**
     * @dev 查询插件地址
     * @param key 插件标识
     * @return 插件合约地址
     */
    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // ========== 插件执行（状态变更） ==========
    /**
     * @dev 调用插件的状态变更函数（如设置成就/武器）
     * @param key 插件标识
     * @param functionSignature 插件函数签名（如"setAchievement(address,string)"）
     * @param user 目标玩家地址（插件操作的对象）
     * @param argument 函数参数（字符串类型，适配基础插件需求）
     */
    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered"); // 校验插件已注册

        // 编码函数调用数据（签名+参数）
        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success, ) = plugin.call(data); // 低级别调用插件（插件自身存储）
        require(success, "Plugin execution failed"); // 校验调用成功
    }

    // ========== 插件查询（只读） ==========
    /**
     * @dev 调用插件的只读函数（如查询成就/武器）
     * @param key 插件标识
     * @param functionSignature 插件函数签名（如"getAchievement(address)"）
     * @param user 目标玩家地址
     * @return 插件返回的字符串结果
     */
    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    ) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered"); // 校验插件已注册

        // 编码函数调用数据（签名+参数）
        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data); // 只读调用（无状态变更）
        require(success, "Plugin view call failed"); // 校验调用成功

        return abi.decode(result, (string)); // 解码返回结果为字符串
    }
}