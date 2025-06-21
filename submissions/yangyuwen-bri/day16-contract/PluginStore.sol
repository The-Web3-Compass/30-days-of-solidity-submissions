//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract PluginStore{
    // 基础玩家信息：名字和头像，用地址来映射
    struct playerProfile{
        string name;
        string avatar;
    }
    mapping(address => playerProfile) public profiles;

    // 插件注册：插件名 => 插件地址
    mapping(string => address) public plugins;

    // 设置、查询玩家信息
    function setPlayer(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = playerProfile(_name, _avatar);
    }
    function getPlayer(address user) external view returns(string memory, string memory) {
        return(profiles[user].name, profiles[user].avatar);
    }

    // 注册插件、查询插件地址
    function registerPlugin(string memory _pluginName, address pluginAddress) external {
        plugins[_pluginName] = pluginAddress;
    }
    function getPlugin(string memory _pluginName) external view returns(address) {
        return(plugins[_pluginName]);
    }

    function runPlugin(
        string memory _pluginName,
        string memory functionSignature,
        address user,
        string memory argument
        ) external {
            address plugin = plugins[_pluginName];
            require(plugin != address(0), "plugin is not registered.");
            
            bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
            (bool sucess, ) = plugin.call(data);
            require(sucess, "plugin execution failed.");
        }

    function runPluginView(
        string memory _pluginName,
        string memory functionSignature,
        address user
    ) external view returns(string memory) {
        address plugin = plugins[_pluginName];
        require(plugin != address(0), "plugin is not registered.");

        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool sucess, bytes memory result) = plugin.staticcall(data);
        require(sucess, "plugin view call failed.");

        return abi.decode(result, (string));
    }


}