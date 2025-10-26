// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AchievementsPlugin {
    

    mapping(address => string) public latestAchievement;

    //定义一个公开函数 setAchievement，用于把 achievement（一个字符串）写入 latestAchievement[user]
    //address user：目标用户地址，指定成就写给谁
    //string memory achievement：成就文本，使用 memory 表示该字符串是临时存在于内存中的拷贝（从外部传入后在内存中）
    function setAchievement(address user, string memory achievement) public {

        //将传入的 achievement 字符串写入合约存储映射 latestAchievement 的 user 键下
        latestAchievement[user] = achievement;
    }

    //义一个公开的只读（view）函数 getAchievement，根据用户地址返回对应的成就字符串
    function getAchievement(address user) public view returns (string memory) {

        //从 latestAchievement 映射读取 user 的值并返回
        return latestAchievement[user];
    }
}

