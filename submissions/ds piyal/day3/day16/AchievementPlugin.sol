// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AchievementPlugin {
    mapping(address => string) public latestAchievement;

    function setAchievement(address user, string memory achievement) external {
        latestAchievement[user] = achievement;
    }

    function getAchievement(address user) external view returns (string memory) {
        return latestAchievement[user];
    }
}