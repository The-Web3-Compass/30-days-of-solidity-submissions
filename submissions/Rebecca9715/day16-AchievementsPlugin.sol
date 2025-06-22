  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// 记录成就
contract AchievementsPlugin {
    // user => achievement string
    mapping(address => string) public latestAchievement;

    // Set achievement for a user (called by PluginStore)
    function setAchievement(address user, string memory achievement) public {
        latestAchievement[user] = achievement;
    }

    // Get achievement for a user
    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];
    }
}

