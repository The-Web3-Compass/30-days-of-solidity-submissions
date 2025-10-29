// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WeaponStorePlugin
 * @dev 玩家武器插件，存储/查询玩家当前装备武器
 * 需通过 PluginStore 的 runPlugin/runPluginView 调用
 */
contract WeaponStorePlugin {
    // 玩家地址 → 当前装备武器映射
    mapping(address => string) public equippedWeapon;

    /**
     * @dev 设置玩家当前装备武器（由 PluginStore 调用）
     * @param user 目标玩家地址
     * @param weapon 武器名称（如"Flaming Sword"/"Golden Axe"）
     */
    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }

    /**
     * @dev 查询玩家当前装备武器（由 PluginStore 调用）
     * @param user 目标玩家地址
     * @return 当前装备武器名称
     */
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
}