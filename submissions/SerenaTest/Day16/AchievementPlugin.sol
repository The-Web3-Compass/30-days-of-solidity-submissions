//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AchievementPlugin{
    mapping(address => string) latestAchievement;

    function setAchievement(address user,string memory achievement) public{
        latestAchievement[user] = achievement;
    }

     function getAchievement(address user) view public returns(string memory){
        return latestAchievement[user];
    }
}


