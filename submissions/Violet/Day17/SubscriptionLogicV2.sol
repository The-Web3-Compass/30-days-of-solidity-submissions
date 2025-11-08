// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day17 SubscriptionStorageLayout.sol";


contract SubscriptionLogicV2 is SubscriptionStorageLayout {

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // --- V1 的功能 ---

    function addPlan(uint8 planId, uint256 price, uint256 duration) external onlyOwner {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

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

    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);
    }

    // --- V2 新增的功能 ---

    /**
     * @dev 暂停一个用户的账户 (仅限所有者)。
     */
    function pauseAccount(address user) external onlyOwner {
        subscriptions[user].paused = true;
    }

    /**
     * @dev 恢复一个用户的账户 (仅限所有者)。
     */
    function resumeAccount(address user) external onlyOwner {
        subscriptions[user].paused = false;
    }
}
