// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WeaponStorePlugin {
    // user => weapon name
    mapping(address => string) public equippedWeapon;

    // Set the user's current weapon (called via PluginStore)
    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }

    // Get the user's current weapon
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
}
