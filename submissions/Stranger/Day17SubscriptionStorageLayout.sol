// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {
    address public logicContract;  // 逻辑合约地址
    address public owner;          // 合约管理员

    struct Subscription {
        uint8 planId;   // 订阅计划ID
        uint256 expiry; // 订阅到期时间
        bool paused;    // 订阅是否暂停
    }

    mapping(address => Subscription) public subscriptions;  // 用户 -> 订阅计划
    mapping(uint8 => uint256) public planPrices;            // 订阅计划 -> 订阅价格
    mapping(uint8 => uint256) public planDuration;          // 订阅计划 -> 订阅时长(单位为秒)
}