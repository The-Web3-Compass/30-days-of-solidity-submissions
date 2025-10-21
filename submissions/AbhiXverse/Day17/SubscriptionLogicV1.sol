// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import "./SubscriptionStorageLayout.sol";

contract SubsscriptionLogicV1 is SubscriptionStorageLayout {

    function addplan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    // Function to pause a subscription
    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0," Invalid plan ");
        require(msg.value >= planPrices[planId], "Insufficient funds");

        Subscription storage s = subscriptions[msg.sender];
        if(block.timestamp < s.expiry) {
            s.expiry += planDuration[planId];
        }
        else {
            s.expiry = block.timestamp + planDuration[planId];
        }

        s.planId = planId;
        s.paused = false;
    }

    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);
    }

}
