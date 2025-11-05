 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");

        Subscription storage s = subscriptions[msg.sender];
        if (block.timestamp < s.expiration) {
            s.expiration += planDuration[planId];
        } else {
            s.expiration = block.timestamp + planDuration[planId];
        }

        s.planId = planId;
        s.active = true;
    }

    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiration && s.active);
    }

    function pauseAccount(address user) external {
        subscriptions[user].active = false;
    }

    function resumeAccount(address user) external {
        subscriptions[user].active = true;
    }
}