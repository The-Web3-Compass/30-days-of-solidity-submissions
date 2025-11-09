// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorageLayout.sol";
contract SubscriptionLogicV1 is SubscriptionStorageLayout{
    // 添加新套餐
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }
    // 用户订阅
    function subscribe(uint8 planId)external  payable{
        require(planPrices[planId]>0,"Invaild plan");
        require(msg.value>=planPrices[planId],"Insufficient payment");

        Subscription storage s=subscriptions[msg.sender];
        // 还有时间
        if(block.timestamp<s.expiry){
            
            s.expiry+=planDuration[planId];
        }
        // 订阅过期
        else{
            s.expiry = block.timestamp + planDuration[planId];
        }
        s.planId=planId;
        s.paused=false; //取消暂停订阅，自动“恢复”已暂停的订阅
    }
    // 检查活跃状态
    function isActive(address user)external view returns (bool){
        Subscription memory s=subscriptions[user];
        //未过期+没有暂停订阅
        return (block.timestamp<s.expiry && !s.paused);
    }

}