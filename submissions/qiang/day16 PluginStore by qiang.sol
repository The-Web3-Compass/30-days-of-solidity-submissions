// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PluginStore {

    struct PlayerProfile{
        string name;
        string avatar;
    }
//保存结构体玩家的名称（name）和头像（avater）
    mapping(address => PlayerProfile) public profiles;

    mapping(string => address) public plugins;
//关联玩家地址
    function setProfile(string memory _name, string memory _avatar) external{
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }
//外部函数，用于设置调用者（msg.sender）的玩家资料，将传入的名称和头像赋值给对应的PlayerProfile
    function getProfile(address user) external view returns(string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }
//外部只读函数，根据传入的玩家地址user，获取对应玩家的资料并返回名称和头像
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }
//外部函数，用于注册插件，将插件标识key和对应的合约地址plugAddress存入plugins映射
    function getPlugin(string memory key) external view returns(address) {
        return plugins[key];
    }
//外部制度函数，根据插件标识key，查询并返回对应的插件合约地址
    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success,) = plugin.call(data);
        require(success, "Plugin execution failed");
    }
//外部插件，执行非view类型插件函数。
//先根据  key  获取插件地址并校验是否注册
//然后编码函数调用数据，通过call执行插件函数
//校验执行是否成功。
    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    ) external view returns(string memory){
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");
        return abi.decode(result, (string));
    }
}

//外部只读函数，执行  view  类型插件函数。
//获取插件地址并校验，编码函数调用数据后通过staticcall执行（保证只读）
//校验执行成功后解码返回结果并以字符串形式返回 。
