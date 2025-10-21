//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AchievementsPlugin{

    mapping(address => string) public LatestAchievement;

    function SetAchievement(address user, string memory achievement) public{
        LatestAchievement[user] = achievement;
    }

    function GetAchievement(address user) public view returns(string memory){
        return LatestAchievement[user];
    }
    
}
