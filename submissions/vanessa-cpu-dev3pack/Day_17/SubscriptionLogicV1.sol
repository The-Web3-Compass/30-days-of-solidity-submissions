// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";


contract SubscriptionLogicV1 is SubscriptionStorageLayout {
    functon initialize() external {
       // Can be used to set up initial state if needed
        // For this example, we assume owner is set by Proxy constructor, 
        // but in real world, we'd use an 'initialize' function instead of constructor. 
    }

    function createPlan(uint8 planId, uint256 duration) external {
        require(msg.sender == owner, "Only owner");
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "plan does not exist");
        require(msg.value == planPrices[planId], "Incorrect ETH amount");

        subscriptions[msg.sender] = Subscription({
            planId: planId,
            expiry: block.timestamp + planDuration[planId],
            paused: false
        });

    }

    function isSubscribed(address user) external view returns (bool) {
        return subscriptions[user].expiry > block.timestamp;
    }
}