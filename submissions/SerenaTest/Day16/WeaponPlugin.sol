//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract WeaponPlugin{
    mapping(address => string) weapon;

    function setAchievement(address user,string memory weapons) public{
        weapon[user] = weapons;
    }

     function getAchievement(address user) view public returns(string memory){
        return weapon[user];
    }
}