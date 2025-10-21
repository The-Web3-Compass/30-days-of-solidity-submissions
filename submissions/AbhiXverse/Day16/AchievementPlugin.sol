// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

contract AchievementPlugin {
 
    // mapping to store player achievements
    mapping (address => string) public latestAchievement;

    // function to set player achievement
    function setAchievement(address user, string memory achievement) public {
        latestAchievement[user] = achievement;
    }
 
    // function to get player achievement
    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];
    }

}

