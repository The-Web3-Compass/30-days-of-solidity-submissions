// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AchievementsPlugin
 * @dev 成就插件模块，追踪玩家的最新成就
 *      用于记录如 "First Blood"、"Treasure Hunter" 等成就
 */
contract AchievementsPlugin {
    // 玩家地址 => 成就描述
    mapping(address => string) public latestAchievement;

    /// @notice 设置用户成就（由 PluginStore 调用）
    function setAchievement(address user, string memory achievement) public {
        latestAchievement[user] = achievement;
    }

    /// @notice 获取用户成就
    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];
    }
}