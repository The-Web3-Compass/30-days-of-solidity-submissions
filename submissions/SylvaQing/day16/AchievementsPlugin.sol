// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AchievementsPlugin{
    mapping (address=>string)public latesAchievement;

    function setAchment(address user,string memory achment) public {
        latesAchievement[user]=achment;
    }

    function getAchment(address user)public view returns (string memory){
        return latesAchievement[user];
    }

}