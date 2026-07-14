//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AchievementsPlugin{

    mapping(address => string) public latestAchievement;

    function setAchievement(address user, string memory achievement) public{
        latestAchievement[user] = achievement;
    }

    function getAcheievement(address user)public view returns(string memory){
        return latestAchievement[user];
    }

}

//0x5C7078010eA1046720D08Daef080e1F75bB13682