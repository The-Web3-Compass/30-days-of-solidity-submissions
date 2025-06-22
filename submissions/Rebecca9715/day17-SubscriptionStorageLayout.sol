 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {
    // 逻辑合约的地址：智能合约的实际功能代码
    address public logicContract;
    address public owner;

    struct Subscription {
        // 省gas
        uint8 planId;
        // 记录过期时间，time更大
        uint256 expiry;
        // 是否暂停
        bool paused;
    }

    mapping(address => Subscription) public subscriptions;
    // planID对应的价格和持续时间
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;
}
