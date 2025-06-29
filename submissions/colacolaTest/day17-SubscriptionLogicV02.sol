// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "day17-SubscriptionStorageLayout.sol";

contract SubscriptionLogicV02 is SubscriptionStorageLayout {
    function addPlan(uint8 planID, uint256 price, uint256 duration) external {
        planPrices[planID] = price;
        planDuration[planID] = duration;
    }

    function subscribe(uint8 planID) external payable {
        require(planPrices[planID] > 0, "Invalid plan");
        require(msg.value >= planPrices[planID], "Insufficient payment");

        if(block.timestamp <= subscriptions[msg.sender].expiry) {
          subscriptions[msg.sender].expiry += planDuration[planID];            
        } else {
          subscriptions[msg.sender].expiry = block.timestamp + planDuration[planID];   
        }

        subscriptions[msg.sender].planID = planID;
        subscriptions[msg.sender].paused = false;
    }

    function isActive(address user) external view returns(bool) {
        return(block.timestamp < subscriptions[user].expiry && !subscriptions[user].paused);
    }

    function pauseAccount(address user) external {
        subscriptions[user].paused = true;
    }

    function resumeAccount(address user) external {
        subscriptions[user].paused = false;
    }
}
