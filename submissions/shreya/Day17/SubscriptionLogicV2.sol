// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SubscriptionLogicV1.sol"; // Inherits from V1 to include its functions

contract SubscriptionLogicV2 is SubscriptionLogicV1 {
    event AccountPaused(address indexed user);
    event AccountResumed(address indexed user);

    function pauseAccount(address user) external {
        require(msg.sender == owner, "Only owner can pause accounts");
        pausedAccounts[user] = true;
        emit AccountPaused(user);
    }

    function resumeAccount(address user) external {
        require(msg.sender == owner, "Only owner can resume accounts");
        pausedAccounts[user] = false;
        emit AccountResumed(user);
    }

    // Override isSubscriptionActive to check for paused accounts
    function isSubscriptionActive(address user) external view returns (bool) {
        if (pausedAccounts[user]) {
            return false;
        }
        return userSubscriptions[user].expiryTime >= block.timestamp;
    }
}