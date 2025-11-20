// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AchievementPlugin
 * @dev Adds achievement tracking feature for players.
 */
contract AchievementPlugin {
    struct PlayerData {
        uint256 achievements;
    }

    mapping(address => PlayerData) internal playerData;

    /// @notice Adds achievements to a player
    function addAchievement(address player, uint256 amount) external {
        playerData[player].achievements += amount;
    }

    /// @notice Returns total achievements for a player
    function getAchievements(address player) external view returns (uint256) {
        return playerData[player].achievements;
    }
}
