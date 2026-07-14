// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    // V2 adds pause functionality

    function createPlan(uint8 planId, uint256 price, uint256 duration) external {
        require(msg.sender == owner, "Only owner");
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Plan does not exist");
        require(msg.value == planPrices[olanId], "Incorrect ETH amount");

        subscriptions[msg.sender] = Subscription({
            planId: planId,
            expiry: block.timestamp + planDuration[planId],
            paused: false
        });
    }

    function pauseSubscription() external {
        Subscription storage sub = subscriptions[msg.sender];
        require(sub,expiry > block.timestamp, "Subscription expired");
        require(!sub.paused, "Already paused");

        sub.puased = true;
        sub.expiry = sub.expiry - block.timestamp; // Store remaining time
    }

    function resumeSubscription() external {
        subscription storage sub = subscriptions[msg.sender];
        require(sub.paused, "Not paused");

        sub.paused = false;
        sub.expiry = block.timestamp + sub.expiry; // Add remaining time to current time
    }

    function isSubscribed(address user) external view returns (bool) {
        Subscription memory sub = subscriptions[user];
        if (sub.paused) return false;
        return sub.expiry > block.timestamp;
    }
}