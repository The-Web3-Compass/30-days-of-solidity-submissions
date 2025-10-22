// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionLogicV1 is SubscriptionStorageLayout {
    event PlanAdded(uint256 indexed planId, uint256 price, uint256 duration);
    event Subscribed(address indexed user, uint256 indexed planId, uint256 expiryTime);

    function addPlan(uint256 price, uint256 duration) external {
        require(msg.sender == owner, "Only owner can add plans");
        uint256 planId = nextPlanId;
        plans[planId] = Plan(price, duration, true);
        nextPlanId++;
        emit PlanAdded(planId, price, duration);
    }

    function subscribe(uint256 planId) external payable {
        Plan storage plan = plans[planId];
        require(plan.isActive, "Plan is not active");
        require(msg.value == plan.price, "Incorrect payment amount");

        userSubscriptions[msg.sender] = Subscription({
            planId: planId,
            startTime: block.timestamp,
            expiryTime: block.timestamp + plan.duration
        });

        emit Subscribed(msg.sender, planId, userSubscriptions[msg.sender].expiryTime);
    }

    function isSubscriptionActive(address user) external view returns (bool) {
        return userSubscriptions[user].expiryTime >= block.timestamp;
    }
}