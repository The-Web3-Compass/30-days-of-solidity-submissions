// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AchievementsPlugin {
    //成就系统中的最新成就，更像是只能佩戴一种的成就
    mapping(address => string) public latestAchievement;

    function setAchievement(address _user, string memory _achievement) public {
        latestAchievement[_user] = _achievement;
    }

    function getAchievement(address _user)public view returns(string memory){
        return latestAchievement[_user];
    }
    
}