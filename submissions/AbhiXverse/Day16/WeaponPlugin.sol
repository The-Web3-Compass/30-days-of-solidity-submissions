// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;


contract WeaponStorePlugin {
  
    // mapping to store player equipped weapon
    mapping(address => string) public equippedWeapon;
    
    // function to set player equipped weapon
    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }

    // function to get player equipped weapon
    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
    
}

 


