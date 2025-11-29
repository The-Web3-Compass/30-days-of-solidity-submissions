// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore{
    struct PlayerProfile{
        string name;//为了节省gas
        string avatar;//头像暂时用srting数组
    }
    mapping (address => PlayerProfile) public profiles;
    mapping (string => address)public plugins;//插件注册器，存储插件地址

    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address _user)external view returns(string memory,string memory){
        PlayerProfile memory profile = profiles[_user];
        return (profile.name, profile.avatar);
    }
    // 注册插件
    function registerPlugin(string memory _name, address _pluginAddress) external {
        plugins[_name] = _pluginAddress;
    }

    // 执行插件 ：知道插件名
    function runPlugin(
        string memory _name,
        string memory _functionSignature,
        address _user,
        string memory _argument)external  {
            address plugin = plugins[_name];//得到插件地址
            require(plugin!=address(0)," Not exist");
            //根据字符串 key 找插件合约
            //然后调用这个插件合约里的某个函数（functionSignature）并传入参数。
            bytes memory data = abi.encodeWithSignature(_functionSignature, _user,_argument);
            (bool success, ) = plugin.call(data);
            require(success,"exection failed");
    }

    function runPluginView(
        string memory _name,
        string memory _functionSignature,
        address _user
    )external view  returns(string memory){
        address plugin = plugins[_name];//得到插件地址
        require(plugin!=address(0)," Not exist");
        bytes memory data = abi.encodeWithSignature(_functionSignature, _user);
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success,"view call failed");
        return abi.decode(result, (string));
    
    }

}