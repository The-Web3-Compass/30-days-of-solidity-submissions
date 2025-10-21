// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract AchievementsPlugin {
    //变量
    mapping(address => string) public latestAchievement;
    //string这里写的是成就名
    //写了public系统会自动生成一个getter，这个叫自动getter
    //自动 getter 不支持条件访问
    function setAchievement(address user, string memory achievement) public {
    latestAchievement[user] = achievement;
    //正在更新其成就的玩家。这是手动传入的
    //更新映射，这个函数有意保持开放状态，就可以被调用了
}
function getAchievement(address user) public view returns (string memory) {
    return latestAchievement[user];
    //简单地查看用户成就
    //手写一个函数来返回数据，这个叫自定义getter
    //写自定义getter可以在不改接口签名的情况下，内部替换数据结构
    //gpt：前面写了public 这个没什么用

}

//0xD4Fc541236927E2EAf8F27606bD7309C1Fc2cbee


}