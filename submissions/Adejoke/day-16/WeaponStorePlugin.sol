// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WeaponStorePlugin {
    mapping(address => string[]) private _weapons;

    function addWeapon(address user, string memory weapon) external {
        _weapons[user].push(weapon);
    }

    function getWeapons(address user) external view returns (string memory) {
        string[] memory userWeapons = _weapons[user];
        if (userWeapons.length == 0) {
            return "No weapons equipped";
        }
        
        string memory result = userWeapons[0];
        for (uint i = 1; i < userWeapons.length; i++) {
            result = string(abi.encodePacked(result, ", ", userWeapons[i]));
        }
        return result;
    }
}
