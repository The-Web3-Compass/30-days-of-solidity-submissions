// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout{//这是一个独立的合约，只保存状态变量——它不包含任何函数（除了后面继承的逻辑）。其思想是将存储与逻辑分离，这是代理升级模式的关键部分。
address public logicContract;
address public owner;

struct Subscription{
    uint8 planId;//订阅计划类型？？
    uint256 expiry;//订阅到期时间
    bool paused;//布尔值 暂停
}

mapping(address=>Subscription) public subscriptions;//地址对应订阅
mapping(uint8=>uint256) public planPrices;//订阅计划对应订阅价格
mapping(uint8=>uint256) public planDuration;//订阅计划对应计划时间


}