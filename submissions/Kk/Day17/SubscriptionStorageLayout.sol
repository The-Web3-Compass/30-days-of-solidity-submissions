// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {
    address public logicContract;//contarct where the actual functionality lives
    address public owner;

    struct Subscription {
        uint8 planId;
        uint256 expiry;
        bool paused;
    }

    mapping(address =>Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;
}
