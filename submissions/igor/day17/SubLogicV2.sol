 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDurations[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");

        Subscription storage s = subs[msg.sender];
        if (block.timestamp < s.expiry) {
            s.expiry += planDurations[planId];
        } else {
            s.expiry = block.timestamp + planDurations[planId];
        }

        s.planID = planId;
        s.paused = false;
    }

    function isActive(address user) external view returns (bool) {
        Subscription memory s = subs[user];
        return (block.timestamp < s.expiry && !s.paused);
    }

    function pauseAccount(address user) external {
        subs[user].paused = true;
    }

    function resumeAccount(address user) external {
        subs[user].paused = false;
    }
}

