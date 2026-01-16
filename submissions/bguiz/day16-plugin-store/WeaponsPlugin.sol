// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title WeaponsPlugin
 */
contract WeaponsPlugin {
    struct PlayerData {
        string name;
        bytes32 data;
    }

    // exact same storage layout as plugin store so that delegatecall can be used
    mapping(address => PlayerData) players;

    function addWeapon(address playerAddr, uint8 weaponId) public {
        PlayerData memory p = players[playerAddr];
        bytes32 playerData = p.data;
        playerData = playerData & bytes32(1 << weaponId);
        p.data = playerData;
        players[playerAddr] = p;
    }

    function hasWeapon(address playerAddr, uint8 weaponId) public view returns(bool hasIt) {
        PlayerData memory p = players[playerAddr];
        bytes32 playerData = p.data;
        hasIt = ((uint256(playerData) >> weaponId) & 1) == 1;
    }
}
