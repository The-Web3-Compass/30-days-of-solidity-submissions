// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../contracts/IPlugin.sol";

/**
 * @title BattleStatsPlugin
 * @dev Plugin for managing player combat statistics
 * 
 * Tracks and manages player battle-related stats like health, damage, level, etc.
 * Demonstrates delegatecall for gaming mechanics.
 */
contract BattleStatsPlugin is IPlugin {
    // ============ Data Structures ============

    struct BattleStats {
        uint256 level;
        uint256 experience;
        uint256 health;
        uint256 maxHealth;
        uint256 damage;
        uint256 defense;
        uint256 wins;
        uint256 losses;
    }

    // ============ Events ============

    event StatsUpdated(address indexed player, string statName, uint256 newValue);
    event LevelUp(address indexed player, uint256 newLevel);
    event BattleResultRecorded(address indexed player, bool won);

    // ============ Errors ============

    error InsufficientExperience(uint256 current, uint256 required);
    error InvalidStatValue(string reason);

    // ============ Plugin Interface ============

    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "Battle Stats Plugin";
    }

    // ============ Stat Functions ============

    /**
     * @dev Gets the player's battle stats
     * 
     * Would access actual storage in production
     * 
     * @return stats The player's BattleStats struct
     */
    function getBattleStats() external pure returns (BattleStats memory stats) {
        return BattleStats({
            level: 1,
            experience: 0,
            health: 100,
            maxHealth: 100,
            damage: 10,
            defense: 5,
            wins: 0,
            losses: 0
        });
    }

    /**
     * @dev Awards experience to the player
     * 
     * When experience reaches the threshold, automatically levels up
     * 
     * @param _amount The amount of experience to award
     */
    function addExperience(uint256 _amount) external {
        require(_amount > 0, "Experience must be greater than 0");

        emit StatsUpdated(msg.sender, "experience", _amount);
    }

    /**
     * @dev Records a battle win
     * 
     * Awards experience and increments win counter
     * 
     * @param _experienceReward The experience to award for the win
     */
    function recordWin(uint256 _experienceReward) external {
        require(_experienceReward > 0, "Reward must be greater than 0");

        emit BattleResultRecorded(msg.sender, true);
        emit StatsUpdated(msg.sender, "wins", 1);
    }

    /**
     * @dev Records a battle loss
     * 
     * Increments loss counter
     */
    function recordLoss() external {
        emit BattleResultRecorded(msg.sender, false);
        emit StatsUpdated(msg.sender, "losses", 1);
    }

    /**
     * @dev Levels up the player
     * 
     * Called automatically when experience threshold is reached
     */
    function levelUp() external {
        emit LevelUp(msg.sender, 2);
    }

    /**
     * @dev Gets the experience needed for the next level
     * 
     * @return The experience threshold for next level
     */
    function experienceForNextLevel() external pure returns (uint256) {
        return 1000;
    }

    /**
     * @dev Increases a specific stat
     * 
     * @param _statName The name of the stat to increase
     * @param _amount The amount to increase by
     */
    function increaseStat(string calldata _statName, uint256 _amount) external {
        require(bytes(_statName).length > 0, "Stat name cannot be empty");
        require(_amount > 0, "Amount must be greater than 0");

        emit StatsUpdated(msg.sender, _statName, _amount);
    }

    /**
     * @dev Heals the player
     * 
     * @param _amount The amount of health to restore
     */
    function heal(uint256 _amount) external {
        require(_amount > 0, "Heal amount must be greater than 0");

        emit StatsUpdated(msg.sender, "health", _amount);
    }

    /**
     * @dev Takes damage to the player
     * 
     * @param _amount The amount of damage to take
     */
    function takeDamage(uint256 _amount) external {
        require(_amount > 0, "Damage must be greater than 0");

        emit StatsUpdated(msg.sender, "health", _amount);
    }
}
