// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../contracts/IPlugin.sol";

/**
 * @title AchievementsPlugin
 * @dev Plugin for managing player achievements
 * 
 * This plugin demonstrates how delegatecall works:
 * - It's a separate contract with achievement logic
 * - When called via delegatecall, it uses the caller's (GameProfile's) storage
 * - This means achievement data is stored in the profile, not here
 * - We can upgrade or modify this logic without touching GameProfile
 */
contract AchievementsPlugin is IPlugin {
    // ============ Storage Layout ============
    // WARNING: When using delegatecall, storage layout MUST match the calling contract
    // The GameProfile contract has storage slots 0-6 for its data.
    // We start using slots 100+ to avoid conflicts.
    // 
    // In a real application, you'd need to carefully manage storage to avoid collisions.
    // This is one of the challenges of delegatecall-based architectures.

    // Slot 100: player => achievementCount (using this as offset to avoid collision)
    // Slot 101+: player => achievement data

    // ============ Data Structures ============

    struct Achievement {
        string title;
        string description;
        uint256 unlockedAt;
        bool active;
    }

    // ============ Events ============

    event AchievementUnlocked(address indexed player, string title);
    event AchievementRevoked(address indexed player, string title);

    // ============ Errors ============

    error AchievementAlreadyExists(string title);
    error AchievementNotFound(string title);
    error InvalidAchievementData(string reason);

    // ============ Plugin Interface ============

    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "Achievements Plugin";
    }

    // ============ Achievement Functions ============
    // These will be called via delegatecall, so they read/write to GameProfile's storage

    /**
     * @dev Unlocks an achievement for the calling player
     * 
     * When called via delegatecall:
     * - msg.sender is the original caller (the player via GameProfile)
     * - Storage belongs to GameProfile
     * - This function modifies GameProfile's storage to track achievements
     * 
     * @param _title The achievement title
     * @param _description The achievement description
     */
    function unlockAchievement(string calldata _title, string calldata _description) external {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_title).length <= 50, "Title too long");
        require(bytes(_description).length <= 200, "Description too long");

        // In a real implementation, we'd store achievements properly
        // For this example, we'll use a simplified mapping approach
        // In production, use proper storage slots or assembly for collision safety

        emit AchievementUnlocked(msg.sender, _title);
    }

    /**
     * @dev Gets the achievement data (would need proper storage implementation)
     * 
     * @param _index The achievement index
     * @return title The achievement title
     */
    function getAchievement(uint256 _index) external pure returns (string memory title) {
        // Simplified for demonstration
        // In production, implement proper storage access with assembly
        return "Achievement";
    }

    /**
     * @dev Gets the count of achievements (demonstrates storage access)
     * 
     * @return The number of unlocked achievements
     */
    function getAchievementCount() external pure returns (uint256) {
        // Simplified for demonstration
        // In production, would access actual storage
        return 0;
    }

    /**
     * @dev Checks if player has a specific achievement
     * 
     * @param _title The achievement title to check
     * @return Whether the achievement is unlocked
     */
    function hasAchievement(string calldata _title) external pure returns (bool) {
        // Simplified for demonstration
        return false;
    }
}
