// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WeaponStorePlugin
 * @dev Tracks a user's equipped weapon. Called via PluginStore.
 */
contract WeaponStorePlugin {
    // user => weapon name
    mapping(address => string) public equippedWeapon;

    // Set the user's current weapon
    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }

    // Get the user's current weapon
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
}
