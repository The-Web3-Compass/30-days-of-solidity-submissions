
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Build an upgradeable subscription manager for a SaaS-like 
// dApp. The proxy contract stores user subscription 
// info (like plans, renewals, and expiry dates), 
// while the logic for managing subscriptions—adding plans, 
// upgrading users, pausing accounts—lives in an 
// external logic contract. When it's time to add 
// new features or fix bugs, you simply deploy a 
// new logic contract and point the proxy to it using 
// delegatecall, without migrating any data. 
// This simulates how real-world apps push updates 
// without asking users to reinstall. You'll learn 
// how to architect upgrade-safe contracts using 
// the proxy pattern and delegatecall, separating 
// storage from logic for long-term maintainability.


// Let’s bring this idea to life by building a modular subscription manager, 
// the kind you'd use for a SaaS app or dApp.

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
    mapping(uint8 => uint256) public planDuration;
}

