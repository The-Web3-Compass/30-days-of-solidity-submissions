// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {

    // 逻辑合约地址
    address public logicContract;
    address public owner;


    // 计划
    struct Subscription {
        uint8 planId;
        // 计划时长
        uint256 expiry;
        // 计划是否暂停
        bool paused;
    }

    // 用户订阅计划的映射
    mapping(address => Subscription) public subscriptions;
    // 计划价格
    mapping(uint8 => uint256) public planPrices;
    // 每个计划持续多长时间
    mapping(uint8 => uint256) public planDuration;

}