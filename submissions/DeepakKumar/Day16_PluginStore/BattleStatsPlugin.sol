// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BattleStatsPlugin
 * @dev Tracks battle performance (wins and losses) for players.
 */
contract BattleStatsPlugin {
    struct Stats {
        uint256 battlesWon;
        uint256 battlesLost;
    }

    mapping(address => Stats) internal battleStats;

    /// @notice Record a win for a player
    function recordWin(address player) external {
        battleStats[player].battlesWon++;
    }

    /// @notice Record a loss for a player
    function recordLoss(address player) external {
        battleStats[player].battlesLost++;
    }

    /// @notice Returns total wins and losses for a player
    function getStats(address player) external view returns (uint256, uint256) {
        Stats storage s = battleStats[player];
        return (s.battlesWon, s.battlesLost);
    }
}
