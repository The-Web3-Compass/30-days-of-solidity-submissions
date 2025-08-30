// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract WeaponStorePlugin {
    mapping(address => string) bag;

    function setWeapon(address _user, string memory _weapon) external{
        bag[_user] = _weapon;
    }

    function getWeapon(address _user) public view returns(string memory){
        return bag[_user];
    }
}