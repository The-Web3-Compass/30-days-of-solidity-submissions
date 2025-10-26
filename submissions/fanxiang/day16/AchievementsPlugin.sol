// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AchievementsPlugin
 * @dev 玩家成就插件，存储/查询玩家最新解锁成就
 * 需通过 PluginStore 的 runPlugin/runPluginView 调用
 */
contract AchievementsPlugin {
    // 玩家地址 → 最新成就映射
    mapping(address => string) public latestAchievement;

    /**
     * @dev 设置玩家最新成就（由 PluginStore 调用）
     * @param user 目标玩家地址
     * @param achievement 成就名称（如"First Blood"/"Master Collector"）
     */
    function setAchievement(address user, string memory achievement) public {
        latestAchievement[user] = achievement;
    }

    /**
     * @dev 查询玩家最新成就（由 PluginStore 调用）
     * @param user 目标玩家地址
     * @return 最新成就名称
     */
    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];
    }
}