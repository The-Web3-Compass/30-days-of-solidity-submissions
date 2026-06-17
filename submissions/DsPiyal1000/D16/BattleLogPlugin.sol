// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BattleLogPlugin {
    struct Battle {
        address opponent;
        bool victory;
        uint256 timestamp;
    }  

    mapping(address => Battle[]) private battleLogs;

    event BattleRecorded(address indexed user, address indexed opponent, bool victory, uint256 timestamp);

    function recordBattle(address user, address opponent, bool victory) external {
        require(user != address(0) && opponent != address(0), "Invalid address");
        require(user != opponent, "Cannot battle self");
        uint256 timestamp = block.timestamp;
        battleLogs[user].push(Battle(opponent, victory, timestamp));
        emit BattleRecorded(user, opponent, victory, timestamp);
    }

    function getBattleCount(address user) external view returns (uint256) {
        return battleLogs[user].length;
    }

    function getBattle(address user, uint256 index) external view returns (address, bool, uint256) {
        require(index < battleLogs[user].length, "Invalid index");
        Battle memory battle = battleLogs[user][index];
        return (battle.opponent, battle.victory, battle.timestamp);
    }
}