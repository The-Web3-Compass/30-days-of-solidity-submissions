//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {
    address owner;
    address currentLogicContract;

    struct Subscription {
        uint8 planId;
        uint256 timeExpiry;
        bool isPaused;
    }

    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint8) public planPrices;
    mapping(uint8 => uint256) public planDurations;
}