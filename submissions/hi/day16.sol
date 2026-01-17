// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//多合同 day16和day17 一起
//web3.0游戏合同 存游戏玩家名字 昵称 头像 武器 社交互动等
//合同模块化 用插件形式搞定其他合同
//call：一个合同叫另一个合同去做xx
//delegatecall 从另一个合约中借用逻辑 ，数据存在于您的合约中，但逻辑来自其他地方。
//staticcall 静态调用 ，非常适合查看或纯粹的功能

contract PluginStore {

    struct PlayerProfile {
        string name;
        string avatar;
    }
    //玩家信息
    mapping(address => PlayerProfile) public profiles;
    //映射profile
    mapping(string => address) public plugins;
    //weapons这样的字符会链接到武器地址
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
        //struct写入mapping 和以前一样
    }
    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        //写入数据 暂时储存 大家都能看到自己的数据
        return (profile.name, profile.avatar);
    }

    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }
    //写插件，相当于注册，把插件放进系统里，回头可以用别的地址插入检索

    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
        //看插件是不是已经注册了？用key找回address
    }
    function runPlugin(
        //要提供的东西：
    string memory key,
    string memory functionSignature,
    address user,
    string memory argument
    
) external {
    //用签名召唤插件
    address plugin = plugins[key];
    //键来检索插件地址
    require(plugin != address(0), "Plugin is not registered");

    bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
    //abi二进制编码 functionSignature,是武器库之类的编译，结合用户信息一起编码
    (bool success, ) = plugin.call(data);
    
    require(success, "Plugin execution failed");
    //这个插件可以在这里写入，更改状态，更新武器之类的
}
function runPluginView(
    string memory key,
    string memory functionSignature,
    address user
    //返回一些值的函数
) external view returns (string memory) {
    address plugin = plugins[key];
    //先抓到这个插件
    require(plugin != address(0), "Plugin not registered");


    bytes memory data = abi.encodeWithSignature(functionSignature, user);
    //static call这次用这个
    (bool success, bytes memory result) = plugin.staticcall(data);
    //需要返回结果
    require(success, "Plugin view call failed");

    return abi.decode(result, (string));
    //解码之前的abi
    //把返回值转换成字符串
    //无风险高效获取插件数据

  }
  //这个是主合同，还要写的是两个插件合同，把两个合同插进来，这个合同就生效

}

    