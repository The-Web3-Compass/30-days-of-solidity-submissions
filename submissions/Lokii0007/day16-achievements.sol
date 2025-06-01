// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract AcievementsPlugin {
    mapping(address => string[]) latestAchievement;

    function setAchievement(address _user, string memory _achievement) external{
        latestAchievement[_user].push(_achievement);
    }

    function getAchievement(address _user) public view returns(string[] memory){
        return latestAchievement[_user];
    }
}