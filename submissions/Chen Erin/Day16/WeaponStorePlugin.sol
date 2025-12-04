// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WeaponStorePlugin
 * @dev 武器插件模块，追踪玩家装备的武器
 */
contract WeaponStorePlugin {
    // 玩家地址 => 当前武器
    mapping(address => string) public equippedWeapon;

    /// @notice 设置玩家当前武器
    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }

    /// @notice 获取玩家当前武器
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
}