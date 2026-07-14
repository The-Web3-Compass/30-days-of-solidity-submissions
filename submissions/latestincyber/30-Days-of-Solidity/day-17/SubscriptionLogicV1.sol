// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

// This contract can be used to set up initial state if needed
// Initial logic for plans and subscriptions

contract SubscriptionLogicV1 is day-17/SubscriptionStorageLayout {
    function initialize() external {
        // Example assuming owner is set by Proxy constructor, but irl we'd use an 'initialize' function instead of constructor
    }

    function createPlan(uint8 planId, uint256 price, uint256 duration) external {
        require(msg.sender == owner, "Owner only");
            require(duration > 0, "Duration must be greater than 0");
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

    function isSubscribed(address user) external view returns (bool) {
        return subscriptions[user].expiry > block.timestamp;
    }
}