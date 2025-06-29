//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day17SubscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    //思考一下需要增加什么功能？
    
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

    //以上的内容和version1 是一模一样的，为什么不继承？
    //因为2发布了，1就没有用了,加新功能在1的下面就ok
    function pauseAccount(address user) external {
    subscriptions[user].paused = true;
}
//手动暂停用户的帐户，不会触及到期时间
function resumeAccount(address user) external {
    subscriptions[user].paused = false;
}
//重新启用已暂停的订阅

//逐个deploy全部的合同





}