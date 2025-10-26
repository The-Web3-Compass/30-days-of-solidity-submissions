// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//这个是代理和逻辑合约都理解的共享大脑,定义代理和逻辑合约的内存结构

contract SubscriptionStorageLayout {
    address public logicContract;  //实际功能所在逻辑合约的地址
    address public owner;

    struct Subscription {
        uint8 planId; //用户计划的标识符
        uint256 expiry; //订阅到期的时间戳
        bool paused;
    }

    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;

}