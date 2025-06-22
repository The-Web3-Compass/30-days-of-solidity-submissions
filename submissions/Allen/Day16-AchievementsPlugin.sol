// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AchievementsPlugin{
    // The key is player
    mapping(address => string) public latestAchievement;

    function setAchievement(address user, string memory achievement) public {
        require(user != address(0),"Invaild user");
        latestAchievement[user] = achievement;
    }

    function getAchievement(address user) public view returns (string memory) {
        require(user != address(0),"Invaild user");
        return latestAchievement[user];
    }
}