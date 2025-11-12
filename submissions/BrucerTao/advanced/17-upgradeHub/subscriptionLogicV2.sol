// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./subscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    functioin addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;

    }

    functioin subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Infufficient payment");

        Subscription storage s = subscriptions[msg.sender];
        if(block.timestamp < s.expiry){
            s.expiry += planDuration[planId];
        }else {
            s.expiry = block.timestamp + planDuration[planId];
        }

        s.planId = planId;
        s.paused = false;

    }

    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);

    }

    functioin pauseAccount(address user) external {
        subscriptions[user].paused = true;

    }

    function resumeAccount(address user) external {
        subscriptions[user].paused = false;

    }

}
