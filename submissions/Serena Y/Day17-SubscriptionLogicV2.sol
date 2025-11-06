// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day17-SubscriptionLogicV1.sol";

contract  SubscriptionLogicV2 is SubscriptionLogicV1 {
      function addPlan(uint8 planId, uint256 price, uint256 duration) external override  {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    function subscribe(uint8 planId) external payable override {
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

    function isActive(address user) external view override returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);
    }

    function pause(address user) external  {
        //一个叫做暂停的函数，需要入手用户地址，对外部可见
        require(msg.sender == user, "Not authorized");
        //需要满足msg.sender等于user，
        subscriptions[user].paused = true;
        //将subscriptions[user].paused设置为true
    }

    function resumeAccount(address user) external{
        require(msg.sender==user,"Not authorized");
        subscriptions[user].paused=false;
    }
}
    
