// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day17_SubscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout{
    // 新增计划
    function addPlan(
        uint8 planId,
        uint256 price,
        uint256 duration
    ) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    // 订阅或续费
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

    // 查询计划是否过期
    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);
    }

    // 关闭计划
    function pauseAccount(address user) external {
        subscriptions[user].paused = true;
    }

    // 开启计划
    function resumeAccount(address user) external {
        subscriptions[user].paused = false;
    }
}