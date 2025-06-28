// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PluginStore {

    // --- 核心玩家资料 ---
    struct PlayerProfile {
        string name;
        string avatar; // 例如，一个指向IPFS的图片链接
    }
    mapping(address => PlayerProfile) public profiles;

    // --- 插件注册表 ---
    // 插件名称 -> 插件合约地址
    mapping(string => address) public plugins;
    
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ========== 核心资料逻辑 ==========

    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (PlayerProfile memory) {
        return profiles[user];
    }

    // ========== 插件管理 (仅限所有者) ==========

    function registerPlugin(string memory key, address pluginAddress) external onlyOwner {
        plugins[key] = pluginAddress;
    }

    // ========== 插件执行 ==========

    /**
     * @dev 执行一个会改变状态的插件函数。使用 `call`。
     * @param key 插件的注册名 (如 "ACHIEVEMENTS")。
     * @param functionSignature 函数签名 (如 "setAchievement(address,string)")。
     * @param user 目标用户地址。
     * @param argument 要传递给插件函数的字符串参数。
     */
    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        // 将函数签名和参数编码成底层调用数据
        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        
        // 使用 call 向插件合约发起一个调用。插件将在它自己的存储空间中执行逻辑。
        (bool success, ) = plugin.call(data);
        require(success, "Plugin execution failed");
    }

    /**
     * @dev 执行一个只读的插件函数。使用 `staticcall`。
     * @param key 插件的注册名。
     * @param functionSignature 函数签名 (如 "getAchievement(address)")。
     * @param user 目标用户地址。
     */
    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    ) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        // 编码调用数据
        bytes memory data = abi.encodeWithSignature(functionSignature, user);

        // 使用 staticcall，确保插件不能修改任何状态
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");

        // 将返回的字节数据解码成字符串
        return abi.decode(result, (string));
    }
}
