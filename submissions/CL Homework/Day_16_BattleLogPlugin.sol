// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BattleLogPlugin
 * @dev Stores and retrieves player battle records.
 */
contract BattleLogPlugin {
    struct Battle {
        address opponent;
        string result; // e.g., "WIN", "LOSE", "DRAW"
        uint256 timestamp;
    }

    mapping(address => Battle[]) private battleLogs;

    /// @notice Log a battle result.
    function recordBattle(address user, address opponent, string memory result) public {
        battleLogs[user].push(Battle({
            opponent: opponent,
            result: result,
            timestamp: block.timestamp
        }));
    }

    /// @notice Get all battle records of a player.
    function getBattles(address user) public view returns (Battle[] memory) {
        return battleLogs[user];
    }

    /// @notice Get the latest battle result.
    function getLastBattle(address user) public view returns (string memory) {
        uint256 count = battleLogs[user].length;
        if (count == 0) return "No battles yet";
        return battleLogs[user][count - 1].result;
    }
}
