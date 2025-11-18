// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 蓝图,只保存状态变量
contract SubscriptionStorageLayout {
    address public logicContract;
    address public owner;

    struct Subscription{
        uint8 planId; //用户套餐
        uint256 expiry; //订阅到期时间/时间戳
        bool paused;//不删除情况下停用订阅
    }

    mapping(address => Subscription) public subscriptions;
    // 每个套餐需要多少 ETH
    mapping(uint8 => uint256) public planPrices;
    // 每个套餐持续多久
    mapping(uint8 => uint256) public planDuration;
}