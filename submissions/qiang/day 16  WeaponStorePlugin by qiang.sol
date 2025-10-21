// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WeaponStorePlugin {
    mapping(address => string) public equippedWeapon;

    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }
//公共函数，接收用户地址  user  和武器名称  weapon 
//将该武器名称赋值给对应用户地址在equippedWeapon映射中的值
//用于设置用户当前装备的武器。
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
}
//公共只读函数（ view  修饰 ），接收用户地址  user 
//从equippedWeapon映射中读取并返回该用户对应的武器名称
//用于查询用户当前装备的武器。


//这段代码实现了一个简单的武器存储插件合约，可配合主合约（如PluginStore）
//在 Web3 游戏等场景中，实现用户武器装备状态的设置和查询功能 。
