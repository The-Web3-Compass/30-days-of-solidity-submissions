//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract WeaponStorePlugin{
    mapping(address => string) public euippedWeapon;

    function setWeapon(address user,string memory weapon) public {
        euippedWeapon[user] = weapon;
    }

    function getWeapon(address user) public view returns(string memory) {
        return euippedWeapon[user]; 
    }
}
