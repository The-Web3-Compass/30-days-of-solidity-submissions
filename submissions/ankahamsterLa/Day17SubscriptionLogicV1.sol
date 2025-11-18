//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// First logic version: add subscription plans, let users subscribe and check if a user is active.

import "./Day17SubscriptionStorageLayout.sol";

// All storage updates will happen in the proxy's memory(via "delegatecall") so both contracts must share the exact memory layout.
// This contract handles: adding new plans, subscribing user and checking active status.
contract SubscriptionLogicV1 is SubscriptionStorageLayout{
    function addPlan(uint8 planId,uint256 price,uint256 duration) external{
        planPrices[planId]=price;
        planDuration[planId]=duration;
    }

    function subscribe(uint8 planId) external payable{
        require(planPrices[planId]>0,"Invalid plan");
        require(msg.value>=planPrices[planId],"Insufficient payment");

        Subscription storage s=subscriptions[msg.sender];
        // If the user already has time left, add the new duration to the current expiry and lets them extend their subscription
        if(block.timestamp<s.expiry){
            s.expiry+=planDuration[planId];
        }
        // If the subscription expired
        else{
            s.expiry=block.timestamp+planDuration[planId];
        }
        s.planId=planId;
        s.paused=false;
    }

    function isActive(address user) external view returns(bool){
        Subscription memory s=subscriptions[user];
        return(block.timestamp<s.expiry&&!s.paused);
    }
}