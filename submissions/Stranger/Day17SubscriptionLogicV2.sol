// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day17SubscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    // 添加订阅计划
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    // 订阅
    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");

        Subscription storage s = subscriptions[msg.sender];
        if (block.timestamp < s.expiry) {
            s.expiry += planDuration[planId];
        } else {
            s.expiry = block.timestamp + planDuration[planId];
        }

        s.planId = planId;
        s.paused = false;
    }

    // 检查订阅是否有效
    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return block.timestamp < s.expiry && !s.paused;
    }

    // 暂停订阅
    function pauseAccount(address user) external {
        subscriptions[user].paused = true;
    }

    // 恢复订阅
    function resumeAccount(address user) external {
        subscriptions[user].paused = false;
    }
}