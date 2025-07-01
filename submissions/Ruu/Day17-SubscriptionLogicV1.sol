//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionLogicV1 is SubscriptionStorageLayout{

    function AddPlan(uint8 PlanId, uint256 price, uint256 duration) external{
        PlanPrices[PlanId] = price;
        PlanDuration[PlanId] = duration;
    }

    function Subscribe(uint8 PlanId) external payable{
        require(PlanPrices[PlanId] > 0, "Invalid plan");
        require(msg.value >= PlanPrices[PlanId], "Insufficient funds");

        Subscription storage S = subscriptions[msg.sender];
        if(block.timestamp < S.Expiry){
            S.Expiry += PlanDuration[PlanId];
        }
        else{
            S.Expiry = block.timestamp + PlanDuration[PlanId];
        }

        S.PlanId = PlanId;
        S.paused = false;
    }

    function isActive(address user) external view returns(bool){
        Subscription memory S = subscriptions[user];
        return(block.timestamp < S.Expiry && !S.paused);
    }
    
}
