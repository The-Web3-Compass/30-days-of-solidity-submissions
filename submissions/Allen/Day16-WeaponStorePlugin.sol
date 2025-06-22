// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WeaponStorePlugin{
    // user => weapon name
    mapping(address => string) public equippedWeapon;

    // Set the user's current weapon (called via PluginStore)
    function setWeapon(address user, string memory weapon) public {
        require(user != address(0),"Invaild user");
        equippedWeapon[user] = weapon;
    }

    // Get the user's current weapon
    function getWeapon(address user) public view returns (string memory) {
        require(user != address(0),"Invaild user");
        return equippedWeapon[user];
    }

}