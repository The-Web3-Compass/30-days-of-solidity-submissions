// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day17 SubscriptionStorageLayout.sol";

contract SubscriptionLogicV1 is SubscriptionStorageLayout {

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /**
     * @dev 添加或更新一个订阅套餐 (仅限所有者)。
     */
    function addPlan(uint8 planId, uint256 price, uint256 duration) external onlyOwner {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    /**
     * @dev 用户订阅一个套餐。
     */
    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");

        Subscription storage s = subscriptions[msg.sender];
        
        // 如果用户已有有效订阅，则延长；否则，开始新的订阅。
        if (block.timestamp < s.expiry) {
            s.expiry += planDuration[planId];
        } else {
            s.expiry = block.timestamp + planDuration[planId];
        }

        s.planId = planId;
        s.paused = false; // 确保订阅时账户是激活状态
    }

    /**
     * @dev 检查一个用户的订阅是否有效。
     */
    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);
    }
}
