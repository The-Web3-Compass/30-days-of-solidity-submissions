// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AchievementsPlugin {
    // user => latest achievement
    mapping(address => string) public latestAchievement;

    // Set achievement for a user (intended to be called via PluginStore)
    function setAchievement(address user, string memory achievement) public {
        latestAchievement[user] = achievement;
    }

    // Get a user's latest achievement
    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];
    }
}