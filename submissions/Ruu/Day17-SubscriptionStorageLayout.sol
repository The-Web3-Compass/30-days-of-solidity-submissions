//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout{

    address public LogicContract;
    address public Owner;

    struct Subscription{
        uint8 PlanId;
        uint256 Expiry;
        bool paused;
    }

    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public PlanPrices;
    mapping(uint8 => uint256) public PlanDuration;

}
