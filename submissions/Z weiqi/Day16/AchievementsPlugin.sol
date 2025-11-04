//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AchievementsPlugin {
    // string是成就的名称“first kill”
    mapping(address => string) public latestAchievement;

    
    function setAchievement//修改状态的函数
    (address user, //正在更新成就的玩家
    string memory achievement) public {

        latestAchievement[user] = achievement;//更新

    }

    //解锁成就/查看
    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];
    }
}