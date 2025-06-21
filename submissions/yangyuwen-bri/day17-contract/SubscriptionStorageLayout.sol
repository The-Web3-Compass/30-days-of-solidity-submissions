// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {
    address public logicContract; //逻辑合约的地址、唯一标识
    address public owner;

    struct Subscription {
        uint8 planId; //套餐类型、套餐的标识
        uint256 expiry; //订阅到期时间
        bool paused;
    }

    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices; //各个套餐的价格
    mapping(uint8 => uint256) public planDuration; //各个套餐的时长
}

