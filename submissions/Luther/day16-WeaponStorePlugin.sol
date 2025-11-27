// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract WeaponStorePlugin {
    
    //保存每个玩家（地址）当前装备的武器名称
    //address：玩家钱包地址
    //string：玩家装备的武器名
    mapping(address => string) public equippedWeapon;

    //设置某个玩家的当前装备武器
    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;     //equippedWeapon[user] = weapon;：把武器名写入映射
    }

    //读取某个玩家当前装备的武器名称
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
}


