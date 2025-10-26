// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout{
    //only defining here
    address public owner;
    address public logicContract;

    struct Subscription{
        uint8 planID;
        uint256 expiry; //时长
        bool paused;    //暂停
    }

    mapping(address => Subscription) public subs;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDurations; 

}