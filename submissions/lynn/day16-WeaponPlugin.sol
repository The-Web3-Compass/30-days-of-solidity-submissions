//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WeaponPlugin {
    mapping(address => string) public currentWeapon;

    function setCurrentWeapon(address _user, string calldata _weapon) external {
        currentWeapon[_user] = _weapon;
    }

    function getCurrentWeapon(address _user) external view returns(string memory) {
        return currentWeapon[_user];
    }
}