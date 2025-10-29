// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubLayout.sol";

contract SubscriptionLogicV1 is SubscriptionStorageLayout{
    function addPlan(uint8 planID,uint256 price, uint256 duration) external{
        planPrices[planID] = price;
        planDurations[planID] = duration;
    }

    function subscribe(uint8 planID) external payable{
        require(planPrices[planID] > 0);
        require(msg.value >= planPrices[planID],"Insufficient payment");

        Subscription storage sub = subs[msg.sender];
        //用于区分首次订阅和续订约
        if(block.timestamp < sub.expiry){
            sub.expiry += planDurations[planID];
        }
        else{
            sub.expiry = block.timestamp + planDurations[planID];
        }
        sub.planID = planID;
        sub.paused = false;
    }

    function isActive(address user) external view returns (bool){
        Subscription memory s = subs[user];
        return (!s.paused && block.timestamp < s.expiry);
    }
}