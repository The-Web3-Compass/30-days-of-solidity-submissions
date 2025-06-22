//SPDX-License-Identifier: MITAdd commentMore actions
pragma solidity ^0.8.0;
contract WeaponStorePlugin{
    mapping(address => string) public equippedWeapon;
    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }
Add commentMore actions
    function getWeapon(address user) public view returns(string memory){
        return equippedWeapon[user];
    }
}