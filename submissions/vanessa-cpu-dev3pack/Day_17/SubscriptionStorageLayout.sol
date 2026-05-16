// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {
    address public logicContract;
    address public owner;

    struct Subscription {
        uint8 planId;
        uint256 expiry;
        bool paused;
    }

    mapping(address => Subscription) public subscriptons;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;

    //Safety gap to prevent collisions in future upgrades
    uint256[50] private _gap;
}