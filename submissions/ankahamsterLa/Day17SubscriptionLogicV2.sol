//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// An upgraded version with extra powers: everything from V1 but you can pause or resume user accounts.
// We will switch the proxy to point to this contract when we're ready to upgrade.

import "./Day17SubscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout{
    function addPlan(uint8 planId,uint256 price,uint256 duration) external{
        planPrices[planId]=price;
        planDuration[planId]=duration;
    }

    function subscribe(uint8 planId) external payable{
        require(planPrices[planId]>0,"Invalid plan");
        require(msg.value>=planPrices[planId],"Insufficient payment");

        Subscription storage s=subscriptions[msg.sender];
        if(block.timestamp<s.expiry){
            s.expiry+=planDuration[planId];
        }
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

    // Manually pauses a user's account
    function pauseAccount(address user) external{
        subscriptions[user].paused=true;
    }

    // Re-enables a paused subscription
    function resumeAccount(address user) external{
        subscriptions[user].paused=false;
    }
}