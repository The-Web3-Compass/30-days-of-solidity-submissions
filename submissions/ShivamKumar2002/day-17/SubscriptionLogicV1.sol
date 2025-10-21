// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISubscriptionManager.sol";
import "./SubscriptionStorage.sol";

/**
 * @title SubscriptionLogicV1
 * @author Your Name
 * @notice Initial implementation of the subscription management logic.
 * @dev Contains functions for adding plans, subscribing, upgrading, and viewing subscription status.
 * @dev Designed to be called via delegatecall from SubscriptionManagerProxy.
 * @dev IMPORTANT: Assumes the storage layout defined in SubscriptionStorage, starting after proxy reserved slots.
 */
contract SubscriptionLogicV1 is ISubscriptionManager, SubscriptionStorage {

    /**
     * @notice Modifier to restrict function calls to the owner (checking proxy's owner).
     * @dev Uses the _getOwner function from SubscriptionStorage.
     */
    modifier onlyOwner() {
        if (_getOwner() != msg.sender) revert NotOwner();
        _;
    }

    /**
     * @inheritdoc ISubscriptionManager
     */
    function addPlan(string calldata name, uint256 duration) external override onlyOwner {
        uint256 planId = nextPlanId;
        plans[planId] = Plan({ name: name, duration: duration, exists: true });
        nextPlanId++;
        emit PlanAdded(planId, name, duration);
    }

    /**
     * @inheritdoc ISubscriptionManager
     */
    function subscribe(uint256 planId) public virtual override {
        Plan storage plan = plans[planId];
        if (!plan.exists) revert PlanNotFound();

        SubscriptionInfo storage sub = userSubscriptions[msg.sender];
        // Allow subscribing only if no active subscription exists
        if (sub.planId != 0 && sub.expiryTimestamp > block.timestamp) {
            revert AlreadySubscribed();
        }

        uint256 expiry = block.timestamp + plan.duration;
        userSubscriptions[msg.sender] = SubscriptionInfo({
            planId: planId,
            expiryTimestamp: expiry,
            pauseStartTime: 0
        });

        emit Subscribed(msg.sender, planId, expiry);
    }

    /**
     * @inheritdoc ISubscriptionManager
     */
    function upgradeSubscription(uint256 newPlanId) public virtual override {
        Plan storage newPlan = plans[newPlanId];
        if (!newPlan.exists) revert PlanNotFound();

        SubscriptionInfo storage sub = userSubscriptions[msg.sender];
        if (sub.planId == 0) revert NotSubscribed();
        if (sub.expiryTimestamp <= block.timestamp) revert SubscriptionExpired();

        uint256 oldPlanId = sub.planId;
        uint256 newExpiry = block.timestamp + newPlan.duration; // Reset expiry on upgrade

        sub.planId = newPlanId;
        sub.expiryTimestamp = newExpiry;

        emit SubscriptionUpgraded(msg.sender, oldPlanId, newPlanId, newExpiry);
    }

    /**
     * @inheritdoc ISubscriptionManager
     */
    function getPlan(uint256 planId) public virtual view override returns (string memory name, uint256 duration) {
        Plan storage plan = plans[planId];
        if (!plan.exists) revert PlanNotFound();
        return (plan.name, plan.duration);
    }

    /**
     * @inheritdoc ISubscriptionManager
     */
    function getSubscription(address user) public virtual view override returns (uint256 planId, uint256 expiryTimestamp, bool isActive) {
        SubscriptionInfo storage sub = userSubscriptions[user];
        planId = sub.planId;
        expiryTimestamp = sub.expiryTimestamp;
        // V1: Active simply means plan exists and expiry is in the future
        isActive = planId != 0 && expiryTimestamp > block.timestamp;
    }

    /**
     * @inheritdoc ISubscriptionManager
     */
    function planCount() public virtual view override returns (uint256 count) {
        return nextPlanId > 0 ? nextPlanId - 1 : 0;
    }

    // --- V2 Functions (Not implemented in V1) ---

    function pauseSubscription() public virtual override {
        revert("Feature not available in V1");
    }

    function resumeSubscription() public virtual override {
        revert("Feature not available in V1");
    }

    function isPaused(address) public virtual view override returns (bool isPaused_) {
        // V1 logic: subscriptions are never paused.
        return false;
    }
}
