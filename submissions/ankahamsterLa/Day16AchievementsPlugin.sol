//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// This contract is a plugin designed to store each player’s latest unlocked achievement — things like "First Blood", "Master Collector", or "Top 1%".
contract AchievementsPlugin{
    mapping(address=>string) public latesAchievement;// user=>achievement string

    // Set achievement for a user
    function setAchievement(address user,string memory achievement) public{
        latesAchievement[user]=achievement;
    }

    // Get achievement for a user
    function getAchievement(address user) public view returns(string memory){
        return latesAchievement[user];
    }
}