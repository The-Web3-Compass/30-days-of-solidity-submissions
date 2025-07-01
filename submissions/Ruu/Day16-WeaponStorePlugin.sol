//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract WeaponStorePlugin{

    mapping(address => string) public EquippedWeapon;

    function SetWeapon(address user, string memory weapon) public{
        EquippedWeapon[user] = weapon;
    }

    function GetWeapon(address user) public view returns(string memory){
        return EquippedWeapon[user];
    }
    
}
