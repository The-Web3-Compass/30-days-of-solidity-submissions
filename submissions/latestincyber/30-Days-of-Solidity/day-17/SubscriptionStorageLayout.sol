// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// SubscriptionStorageLayout defines the storage layout for a subscription management system.
// This contract is intended to be used as the storage layer for a proxy pattern, where the logic contract can be upgraded without changing the storage layout. It includes:
// - logicContract: Address of the current logic contract that implements the subscription management functionality.
// - owner: Address of the contract owner who can manage subscription plans and upgrade the logic contract.
// - Subscription struct: Contains details about a user's subscription, including the plan ID, expiry timestamp, and paused status.
// - subscriptions mapping: Maps user addresses to their subscription details.
// - planPrices mapping: Maps plan IDs to their respective prices.
// - planDurations mapping: Maps plan IDs to their respective durations in seconds.

contract SubscriptionStorageLayout {
    address public logicContract;
    address public owner;
    
    struct Subscription {
        uint8 planId;
        uint256 expiry;
        bool paused;
    }
    
    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDurations;

    // Reserved storage space to allow for future variable additions without affecting the storage layout
    uint256[50] private __gap; 
}