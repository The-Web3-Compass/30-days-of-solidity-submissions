// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout{
    address public owner;
    //逻辑合约的地址
    address public logicContract;

    struct Subscription{
        uint8 planID;
        uint256 expiry;
        bool paused;
    }

    mapping(address=>Subscription) public subscriptions;
    mapping(uint8=>uint256)public planPrices;
    mapping(uint8 => uint256)public planDuration;

}