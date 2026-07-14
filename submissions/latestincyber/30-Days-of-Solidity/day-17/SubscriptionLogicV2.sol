// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

// Upgraded logic with pause/resume functions

contract SubscriptionLogicV2 is day-17/SubscriptionStorageLayout {
    function createPlan(uint8 planId, uint256 price, uint256 duration) external {
        require(msg.sender == owner, "Owner only");
        planPrices[planId] = price;
        planDurations[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Plan does not exist");
        require(msg.value == planPrices[planId], "Incorrect ETH amount");

        subscriptions[msg.sender] = Subscription({
            planId: planId,
            expiry: block.timestamp + planDurations[planId],
            paused: false
        });
    }

    function pauseSubscription() external {
        Subscription storage sub = subscriptions[msg.sender];
        
        require(sub.expiry > block.timestamp, "Subscription expired");
        require(!sub.paused, "Already paused");

        sub.paused = true;
        sub.expiry = sub.expiry - block.timestamp; // Store remaining time
    }

    function resumeSubscription() external {
        Subscription storage sub = subscriptions[msg.sender];
        
        require(sub.paused, "Subscription not paused");

        sub.paused = false;
        sub.expiry = block.timestamp + sub.expiry; // Add remaining time to current time
    }

    function isSubscribed(address user) external view returns (bool) {
        Subscription memory sub = subscriptions[user];

        if (sub.paused) return false;

        return sub.expiry > block.timestamp;
    }
}