// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SubscriptionStorageLayout
 * @notice 用于串联代理合约和逻辑合约的主合约，相当于规定了存储槽位置
 * @dev 支持调用外部调用delegatecall执行特定逻辑
 */
contract SubscriptionStorageLayout {
    address public subscriptionLogicAddress;//逻辑合约地址，slot 0
    address public owner;//拥有者地址 slot1
    
    
    /**
    * @notice 玩家订阅结构体。
    */
    struct Subscription {
        uint8 planId;//用户套餐标识字
        uint256 expiry;//订阅到期时间
        bool paused;// 临时停用用户的订阅
    }

    mapping (address => Subscription) public subscriptions;//slot 2 跟踪每个用户的信息
    mapping (uint8 => uint256) public planPrices;//套餐价格 slot 3
    mapping (uint8 => uint256) public planDuration;//套餐时间 slot 4

}