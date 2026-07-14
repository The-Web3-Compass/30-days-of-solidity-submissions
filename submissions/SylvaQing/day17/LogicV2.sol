// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// 升级版（带有暂停/恢复功能）
import "./StorageLayout.sol";
contract SubscriptionLogicV2 is SubscriptionStorageLayout{

    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
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

    //========新增功能======== //
    // 暂停
    function pauseAccount(address user)external{
        subscriptions[user].paused=true;
    }
    // 恢复
    function resumeAccount(address user)external {
        subscriptions[user].paused=false;
    }
    
}