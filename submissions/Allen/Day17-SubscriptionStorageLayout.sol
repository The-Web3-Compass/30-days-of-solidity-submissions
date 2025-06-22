// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SubscriptionStorageLayout {
    /**
    This is a standalone contract that only holds state variables.
    It doesn’t include any functions (except for inherited logic later). 
    The idea is to separate storage from logic.
    This layout contract acts like a blueprint that defines 
    the memory structure for both the proxy and the logic contracts.
    */

    address public owner;
    // This stores the current implementation address.
    address public logicContract;

    struct Subscription {
        uint8 planId;
        // expired timestamp
        uint256 expairy;
        // logically delete
        bool paused;
    }

    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;
    mapping (uint8=> uint256) public planDuration;

}