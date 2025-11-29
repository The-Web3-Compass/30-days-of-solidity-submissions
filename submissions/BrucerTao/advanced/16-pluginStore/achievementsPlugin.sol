// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AchievementsPlugin {
    mapping(address => string) public latestAchievement;  //跟踪每个玩家最新成就，比如First Kill

    function setAchievement(address user, string memory achievement) public {
        latestAchievement[user] = achievement;

    }

    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];

    }

}