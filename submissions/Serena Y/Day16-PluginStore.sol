// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {
    struct PlayerProfile {//结构体存储姓名和头像
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;//mapping用户地址映射用户信息

    // === Multi-plugin support ===
    mapping(string => address) public plugins;//mapping插件类型映射插件地址

    // ========== Core Profile Logic ==========

    function setProfile(string memory _name, string memory _avatar) external {//允许玩家  创建或更新  他们的个人资料，通过设置名称和头像
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {//许  任何人  使用钱包地址查询玩家的个人资料
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // ========== Plugin Management ==========

    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // ========== Plugin Execution ==========
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