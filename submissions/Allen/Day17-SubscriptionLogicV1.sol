// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./SubscriptionStorageLayout.sol";

contract SubscriptionLogicV1 is SubscriptionStorageLayout {

    function addPlan(unit8 planId,uint256 price,uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }
 
    function subscribe(uint8 planId) external payable {
       require(planPrices[planId] > 0, "Invalid plan");
       require(msg.value >= planPrices[planId], "Insufficient payment");

       Subscription storage userSubscribe = subscriptions[msg.sender];
        if (block.timestamp < s.expiry) {
            userSubscribe.expiry += planDuration[planId];
        } else {
            userSubscribe.expiry = block.timestamp + planDuration[planId];
        }

        userSubscribe.planId = planId;
        userSubscribe.paused = false;
    }

    function isActive(address user) external view returns(bool){
        require(subscriptions[user] != 0,"Invaild subscription");
        return (block.timestamp < s.expiry && !s.paused);
    }

}