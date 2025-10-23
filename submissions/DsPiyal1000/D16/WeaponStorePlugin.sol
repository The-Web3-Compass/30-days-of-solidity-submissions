// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WeaponStorePlugin {
    mapping(address => bytes32) public equippedWeapon;

    function setWeapon(address user, bytes32 weapon) external {
        require(user != address(0), "Invalid user");
        require(weapon != bytes32(0), "Invalid weapon");
        equippedWeapon[user] = weapon;
    }

    function getWeapon(address user) external view returns (bytes32) {
        return equippedWeapon[user];
    }
}