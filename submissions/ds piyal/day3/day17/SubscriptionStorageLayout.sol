// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Shared memory blueprint
contract SubscriptionStorageLayout {
    address public logicContract;
    address public owner;
    
    struct Subscription {
        uint8 planId;
        uint256 expiry;
        bool paused;
    }
    
    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;
    
    event PlanAdded(uint8 indexed planId, uint256 price, uint256 duration);
    event UserSubscribed(address indexed user, uint8 planId, uint256 expiry);
    event AccountPaused(address indexed user);
    event AccountResumed(address indexed user);
    event LogicUpgraded(address indexed oldLogic, address indexed newLogic);
}