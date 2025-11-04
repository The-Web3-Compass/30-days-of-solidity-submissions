//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract PluginStore{
    struct PlayerProfile{
        string name;
        string avatar;
    }

    mapping(address=>PlayerProfile)public profiles;
    mapping(string=>address)public plugins;
    
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }
    //string memory key: 用于识别插件的名称——可以将其视为 URL 别名或插件名称。
    //address pluginAddress: 你要注册的插件的智能合约地址。
    //plugins[key] = pluginAddress: 将插件添加到系统中，以便后续使用。
    function registerPlugin(string memory key, address pluginAddress) external {
    plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }
    function runPlugin(string memory key, string memory functionSignature, address user,string memory argument) external {
    address plugin = plugins[key];
    require(plugin != address(0), "Plugin not registered");

    bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
    (bool success, ) = plugin.call(data);//plugin：这是目标合约的地址，你想调用的合约。
    require(success, "Plugin execution failed");
}

    function runPluginView(string memory key, string memory functionSignature, address user)external view returns(string memory){
        address plugin = plugins[key];
        require(plugin != address(0), "No plugin found");
        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin execution failed");
        return abi.decode(result,(string));
    }



}