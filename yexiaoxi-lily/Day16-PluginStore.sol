// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }
    //映射存放用户信息
    mapping(address => PlayerProfile) public profiles;

    // 映射存放插件名称对应地址
    mapping(string => address) public plugins;

    // 输入用户信息
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }
    //获取用户信息
    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // 记录插件地址

    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }
    //查询插件地址
    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

//  运行插件(修改状态) - 使用call
function runPlugin(
    string memory key,
    string memory functionSignature,
    address user,
    string memory argument
) external {
    address plugin = plugins[key];
    require(plugin != address(0), "Plugin not registered");
    //编码函数调用
    bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
    //调用插件
    (bool success, ) = plugin.call(data);
    require(success, "Plugin execution failed");
}
// 查询插件(只读) - 使用staticcall
function runPluginView(
    string memory key,
    string memory functionSignature,
    address user
) external view returns (string memory) {
    address plugin = plugins[key];
    require(plugin != address(0), "Plugin not registered");
    //编码函数调用
    bytes memory data = abi.encodeWithSignature(functionSignature, user);
     //只读调用
    (bool success, bytes memory result) = plugin.staticcall(data);
    require(success, "Plugin view call failed");
    // 解码返回数据
    return abi.decode(result, (string));
}

}

//成就插件
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract AchievementsPlugin {
    // 映射 地址对应成就
    mapping(address => string) public latestAchievement;

    // 记录成就
    function setAchievement(address user, string memory achievement) public {
        latestAchievement[user] = achievement;
    }

    // 查询成就
    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];
    }
}

//武器插件

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WeaponStorePlugin
 * @dev Stores and retrieves a user's equipped weapon. Meant to be called via PluginStore.
 */
contract WeaponStorePlugin {
    // 映射 用户地址对应武器
    mapping(address => string) public equippedWeapon;

    // 记录武器
    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }

    // 查询武器
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
}
