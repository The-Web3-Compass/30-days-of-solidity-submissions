// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AchievementPlugin {
    mapping(address => bytes32) public latestAchievement;

    function setAchievement(address user, bytes32 achievement) external {
        require(user != address(0), "Invalid user");
        require(achievement != bytes32(0), "Invalid achievement");
        latestAchievement[user] = achievement;
    }

    function getAchievement(address user) external view returns (bytes32) {
        return latestAchievement[user];
    }
}