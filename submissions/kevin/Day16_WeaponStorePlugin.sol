// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WeaponStorePlugin{
    mapping(address => string) public equippedWeapon;

    function setWeapon(address user, string memory weapon) public {
        require(user != address(0),"Invaild user");
        equippedWeapon[user] = weapon;
    }

    function getWeapon(address user) public view returns (string memory) {
        require(user != address(0),"Invaild user");
        return equippedWeapon[user];
    }

}
