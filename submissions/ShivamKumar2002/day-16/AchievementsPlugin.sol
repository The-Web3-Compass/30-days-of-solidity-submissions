// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AchievementsPlugin
 * @author shivam
 * @notice Manages player achievements via delegatecall from PlayerProfile.
 * @dev Plugin contract for achievement logic. Modifies CALLER (PlayerProfile) storage.
 * Ensure storage slots are allocated in PlayerProfile and avoid collisions.
 */
contract AchievementsPlugin {
    /// @notice Mapping storing achievements unlocked by players (playerAddress => achievementId => isUnlocked).
    /// @dev Resides in the PlayerProfile contract's storage when called via delegatecall.
    mapping(address => mapping(uint256 => bool)) public achievements;

    /// @notice Emitted when a player unlocks an achievement.
    /// @param player Address of the player who unlocked the achievement.
    /// @param achievementId ID of the unlocked achievement.
    /// @dev `msg.sender` in the delegatecall context is the original player calling PlayerProfile.
    event AchievementUnlocked(address indexed player, uint256 indexed achievementId);

    /**
     * @notice Unlocks a specific achievement for the caller (msg.sender of PlayerProfile call).
     * @param _achievementId The ID of the achievement to unlock.
     * @dev Called via delegatecall from PlayerProfile. Modifies 'achievements' mapping
     * in PlayerProfile's storage. Emits {AchievementUnlocked} event.
     */
    function unlockAchievement(uint256 _achievementId) external {
        // msg.sender is the original caller of the PlayerProfile contract
        address player = msg.sender;
        if (!achievements[player][_achievementId]) {
            achievements[player][_achievementId] = true;
            emit AchievementUnlocked(player, _achievementId);
        }
    }

    /**
     * @notice Checks if a player has unlocked a specific achievement.
     * @param _player The address of the player to check.
     * @param _achievementId The ID of the achievement to check.
     * @return bool True if the player has unlocked the achievement, false otherwise.
     * @dev Reads from the 'achievements' mapping in the PlayerProfile contract's storage context.
     */
    function hasAchievement(address _player, uint256 _achievementId) external view returns (bool) {
        return achievements[_player][_achievementId];
    }
}