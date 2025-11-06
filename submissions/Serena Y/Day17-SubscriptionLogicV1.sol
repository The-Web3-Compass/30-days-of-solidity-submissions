// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day17-SubscriptionStorageLayout.sol";

contract SubscriptionLogicV1 is SubscriptionStorageLayout {
    function addPlan(uint8 planId, uint256 price, uint256 duration) external virtual {
        //一个叫addPlan的函数，输入参数，订阅计划，价格，时间
        planPrices[planId] = price;//把价格赋值给对应的订阅计划
        planDuration[planId] = duration;//把订阅事件赋值给对应的订阅计划
    }

    function subscribe(uint8 planId) external virtual payable {
        //一个叫做订阅的函数，输入参数为planId
        require(planPrices[planId] > 0, "Invalid plan");
        //需要满足订阅价格大于0
        require(msg.value >= planPrices[planId], "Insufficient payment");
        //需要满足msg.value大于订阅价格，否则返回
        Subscription storage s = subscriptions[msg.sender];
        //把类型为 Subscription，msg.sender的订阅信息赋值给S，存储类型storage
        if (block.timestamp < s.expiry) {//判断如果当前时间小于截至
            s.expiry += planDuration[planId];//到期时间=截至时间+订阅时间
        } else {//否则的话，截至事件=当前时间+订阅时间
            s.expiry = block.timestamp + planDuration[planId];
        }

        s.planId = planId;//输入的planId赋值给s.planID
        s.paused = false;//暂停为false
    }

    function isActive(address user) external view  virtual returns (bool) {
        //一个叫做isActive的函数用来判断是否有效，输入参数为用户地址，返回布尔值0或者1
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);
        //返回true 当前时间小于 截至时间和没有暂停
    }
}
