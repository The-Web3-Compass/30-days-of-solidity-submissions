//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;


//只保存状态变量，不包含任何函数。
contract SubscriptionStorageLayout {
    address public logicContract;
    address public owner;

    struct Subscription {
        uint8 planId;
        uint256 expiry;
        bool paused;//允许用户暂停或者恢复它们的套餐
    }

    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;
    

}