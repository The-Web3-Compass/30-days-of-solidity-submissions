// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AchievementsPlugin {
    mapping(address => string) public latestAchievement;
//关联玩家地址（ address  类型 ）和对应的成就字符串（ string  类型 ）
//存储每个玩家的最新成就。
    function setAchievement(address user, string memory achievement) public {
        latestAchievement[user] = achievement;
    }
//公共函数，接收玩家地址user和成就内容achievement 
//将该成就赋值给对应玩家地址在latestAchievement映射中的值，用于设置玩家成就。
    function getAchievement(address user) public view returns (string memory) {
        return latestAchievement[user];
    }
}
//公共只读函数（ view  修饰 ）
//接收玩家地址user，从latestAchievement映射中读取并返回该玩家对应的成就字符串
//用于查询玩家成就。

//这段代码实现了一个简单的成就插件合约
//可配合其他主合约，比如之前的PluginStore，为 Web3游戏等场景提供玩家成就的设置和查询功能 。
