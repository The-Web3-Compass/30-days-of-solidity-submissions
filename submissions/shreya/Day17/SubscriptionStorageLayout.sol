// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionStorageLayout {
    struct Plan {
        uint256 price;
        uint256 duration; // in seconds
        bool isActive;
    }

    mapping(uint256 => Plan) internal plans;
    uint256 internal nextPlanId;

    struct Subscription {
        uint256 planId;
        uint256 startTime;
        uint256 expiryTime;
    }

    mapping(address => Subscription) internal userSubscriptions;
    mapping(address => bool) internal pausedAccounts;

    address internal owner;
    address internal logicContract;
}