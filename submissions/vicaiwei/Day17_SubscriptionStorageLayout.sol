// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {
    address public logicContract;
    address public owner;

    struct Subscription {
        uint8 planId;       // small ID to save gas
        uint256 expiry;     // unix timestamp
        bool paused;        // pause toggle
    }

    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;   // planId => price in wei
    mapping(uint8 => uint256) public planDuration; // planId => duration in seconds
}