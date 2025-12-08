// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WeaponStorePlugin {
    mapping(address => string) public equippedWeapon;  //跟踪每个玩家装备了哪些武器

    function setWeapon(address user, string memory weapon) public {
        equippedWeaponp[user] = weapon;

    }

    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];

    }

}