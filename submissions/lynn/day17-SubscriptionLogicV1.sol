//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./day17-SubscriptionStorageLayout.sol";

contract SubscriptionLogicV1 is SubscriptionStorageLayout {
    function addPlan(uint8 _planId, uint8 _price, uint256 _duration) external {
        planPrices[_planId] = _price;
        planDurations[_planId] = _duration;
    }

    function subscribe(uint8 _planId) external payable {
        require(planPrices[_planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[_planId], "Insufficient payment");

        Subscription storage subscription = subscriptions[msg.sender];
        if (block.timestamp < subscription.timeExpiry) {
            subscription.timeExpiry += planDurations[_planId];
        } else {
            subscription.timeExpiry = block.timestamp + planDurations[_planId];
        }
        subscription.planId = _planId;
        subscription.isPaused = false;
    }

    function isActive(address _user) external view returns(bool) {
        require(_user != address(0), "Invalid user address");

        Subscription memory subscription = subscriptions[_user];
        return (block.timestamp < subscription.timeExpiry && !subscription.isPaused);
    }
}