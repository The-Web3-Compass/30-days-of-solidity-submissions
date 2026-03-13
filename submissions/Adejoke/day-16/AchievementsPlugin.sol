// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AchievementsPlugin {
    mapping(address => string[]) private _achievements;

    function addAchievement(address user, string memory achievement) external {
        _achievements[user].push(achievement);
    }

    function getAchievements(address user) external view returns (string memory) {
        string[] memory userAchievements = _achievements[user];
        if (userAchievements.length == 0) {
            return "No achievements yet";
        }
        
        string memory result = userAchievements[0];
        for (uint i = 1; i < userAchievements.length; i++) {
            result = string(abi.encodePacked(result, ", ", userAchievements[i]));
        }
        return result;
    }
}
