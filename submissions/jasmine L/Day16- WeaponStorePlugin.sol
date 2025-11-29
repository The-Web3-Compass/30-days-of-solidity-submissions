// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract  WeaponStorePlugin {
    //武器系统中的最新武器
    mapping(address => string) public latestWeapon;

    function setWeapon(address _user, string memory _latestWeapon) public {
        latestWeapon[_user] = _latestWeapon;
    }

    function getWeapon(address _user)public view returns(string memory){
        return latestWeapon[_user];
    }
    
}