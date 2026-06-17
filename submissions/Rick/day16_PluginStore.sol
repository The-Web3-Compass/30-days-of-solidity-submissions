// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {

     struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping (address => PlayerProfile) public profiles;

    // 插件名称 -》 插件地址
    mapping (string => address) public pluginMap;

    function setPlayerProfile(string memory _name , string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name , _avatar);
    }

    
    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    function registerPlugin(string memory key, address pluginAddress) external {
        pluginMap[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return pluginMap[key];
    }

    /*
        call : 夸合约调用其他合约函数
        执行目标合约的代码，使用目标合约的上下文
        msg.sender 是当前合约，要获取原始调用者，单独作为参数传入
        可传递ETH

        abi.encodeWithSignature("函数名(参数类型...)", 参数值...)
        第一个是签名字符串，
        后面依次传实际参数，
        没参数就不写后面的值，但括号要保留！
    */
    function runPlugins(string memory _pluginName , string memory functionSignature, address user , string memory argument) external {
        address pluginAddr = pluginMap[_pluginName];
        require(pluginAddr != address(0), "not  set");

        bytes memory data = abi.encodeWithSignature(functionSignature, user ,argument);
        (bool success , ) = pluginAddr.call(data);
        require(success , "Plugin execution failed");
    }

    /* 
        delegatecall 使用目标合约的函数逻辑，但是使用当前合约的上下文
        还是在当前合约执行费代码，msg.sender 无变更，还是原始调用者
        不能传递ETH 

        staticcall 安全地读取其他合约的状态或返回值（不会修改状态）
        调用的只能是view和pure函数
    */
    function runPluginView(string memory _pluginName , string memory functionSignature, address user ) external view returns (string memory) {
        address pluginAddr = pluginMap[_pluginName];
        require(pluginAddr != address(0), "not  set");
        
        bytes memory data = abi.encodeWithSignature(functionSignature , user);
        (bool success, bytes memory result) = pluginAddr.staticcall(data);

        require( success , "Plugin view call failed");

        return abi.decode(result,(string));

    }

}