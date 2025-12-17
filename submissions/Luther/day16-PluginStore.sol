//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//定义一个结构体 PlayerProfile，包含两个成员：name 和 avatar，都用 string
contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }
    
    //将以太坊地址映射到玩家档案（Profile）
    mapping(address => PlayerProfile) public profiles;

    //通过 string（插件 key，例如名称或标识符）查找插件合约地址
    mapping(string => address) public plugins;

    //允许调用者为自己设置或更新 PlayerProfile（name 与 avatar）
    function setProfile(string memory _name, string memory _avatar) external {

        //把结构体写入合约的 storage，覆盖该地址原来的 profile（如果有）。写入 storage 很贵，每次调用都会产生 gas
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    //按地址读取用户 profile 并返回 name 与 avatar
    function setProfile(address user) external view returns (string memory, string memory) {

        //把 storage 中的结构体拷贝到内存（read），内存复制也有微量 gas
        PlayerProfile memory profile = profiles[user];

        //返回两个 string
        return (profile.name, profile.avatar);
    }

    //将某个字符串 key 映射到插件合约地址，插件注册 
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    //查询给定 key 对应的插件地址
    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    //runPlugin（执行外部插件，可能改变链上状态）
    //根据 key 找到插件地址，然后对该插件合约发起一次可写的低级 call，
    ///执行由 functionSignature 指定的函数，传参为 (user, argument)。
    //这是一个把控制权交给外部合约的通用桥接器（proxy-like）函数
    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];     //读取插件地址（storage）
        require(plugin != address(0), "Plugin not registered");     //确保插件已注册

        //把函数签名（例如 "doSomething(address,string)"）与参数编码成 calldata（bytes）
        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);

        //低级 call，会把所有剩余 gas 转发给被调用合约
        (bool success, ) = plugin.call(data);

        //如果外部合约执行失败，回滚当前事务并抛出错误信息
        require(success, "Plugin execution failed");
    }


    //runPluginView（调用插件的 view 方法，读取返回字符串）
    //对注册的插件合约做只读调用（staticcall），
    //并把插件返回的 bytes 解码为 string 返回给调用者。
    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    ) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        //把函数签名和参数编码为 calldata
        bytes memory data = abi.encodeWithSignature(functionSignature, user);     

        //staticcall 是低级只读调用，禁止在被调用合约中修改状态,适合调用 view/pure 函数
        (bool success, bytes memory result) = plugin.staticcall(data);

        //如果调用失败（如函数不存在或内部 revert），则回滚
        require(success, "Plugin view call failed");

        //把返回的字节数组按 string 解码并返回
        return abi.decode(result, (string));
    }
}