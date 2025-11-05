//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AchievementPlugin {
    mapping(address => string) public latestAchievement;

    function setLatestAchievement(address _user, string calldata _achievement) external {
        latestAchievement[_user] = _achievement;
    }

    function getLatestAchievement(address _user) external view returns(string memory) {
        return latestAchievement[_user];
    }
}