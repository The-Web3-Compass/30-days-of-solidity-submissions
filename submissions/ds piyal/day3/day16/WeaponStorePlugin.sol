// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract WeaponStorePlugin {
    
mapping(address => string) public equippedWeapon;

    function setWeapon(address user, string memory weapon) external {
        equippedWeapon[user] = weapon;
    }

    function getWeapon(address user) external view returns (string memory) {
        return equippedWeapon[user];
    }
}