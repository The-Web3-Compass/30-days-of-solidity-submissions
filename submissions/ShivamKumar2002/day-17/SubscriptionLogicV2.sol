// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Inherit from V1 to reuse code/storage awareness. We inherit V1 which already inherits ISubscriptionManager and SubscriptionStorage
import "./SubscriptionLogicV1.sol";

/**
 * @title SubscriptionLogicV2
 * @author Your Name
 * @notice Second implementation of subscription logic, adding pause/resume functionality.
 * @dev Extends V1, overriding functions where necessary and adding new ones.
 * @dev Designed to be called via delegatecall from SubscriptionManagerProxy.
 * @dev IMPORTANT: Respects V1 storage layout and appends new state (`pauseStartTime` within SubscriptionInfo struct).
 */
contract SubscriptionLogicV2 is SubscriptionLogicV1 { // Inherit from V1

    /**
     * @notice Overrides V1 subscribe to ensure user is not paused.
     * @inheritdoc ISubscriptionManager
     */
    function subscribe(uint256 planId) public virtual override {
        if (userSubscriptions[msg.sender].pauseStartTime != 0) revert AlreadyPaused();
        // Call V1's subscribe logic
        super.subscribe(planId);
    }

    /**
     * @notice Overrides V1 upgrade to ensure user is not paused.
     * @inheritdoc ISubscriptionManager
     */
    function upgradeSubscription(uint256 newPlanId) public virtual override {
        if (userSubscriptions[msg.sender].pauseStartTime != 0) revert AlreadyPaused();
         // Call V1's upgrade logic
        super.upgradeSubscription(newPlanId);
    }

    /**
     * @inheritdoc ISubscriptionManager
     * @dev Pauses the user's subscription by recording the pause start time.
     */
    function pauseSubscription() public virtual override {
        SubscriptionInfo storage sub = userSubscriptions[msg.sender];

        if (sub.planId == 0) revert NotSubscribed();
        if (sub.expiryTimestamp <= block.timestamp) revert SubscriptionExpired();
        if (sub.pauseStartTime != 0) revert AlreadyPaused(); // Already paused

        sub.pauseStartTime = block.timestamp;
        emit SubscriptionPaused(msg.sender, sub.pauseStartTime);
    }

    /**
     * @inheritdoc ISubscriptionManager
     * @dev Resumes a paused subscription, extending the expiry date by the duration paused.
     */
    function resumeSubscription() public virtual override {
        SubscriptionInfo storage sub = userSubscriptions[msg.sender];

        if (sub.planId == 0) revert NotSubscribed();
        if (sub.pauseStartTime == 0) revert NotPaused();

        uint256 pausedDuration = block.timestamp - sub.pauseStartTime;
        sub.expiryTimestamp += pausedDuration;
        sub.pauseStartTime = 0;

        emit SubscriptionResumed(msg.sender, sub.expiryTimestamp);
    }

    /**
     * @inheritdoc ISubscriptionManager
     * @dev Checks if a user's subscription is currently in a paused state.
     */
    function isPaused(address user) public view override returns (bool isPaused_) {
        return userSubscriptions[user].pauseStartTime != 0;
    }

     /**
     * @notice Overrides V1 getSubscription to factor in the paused state for `isActive`.
     * @inheritdoc ISubscriptionManager
     */
    function getSubscription(address user) public view override returns (uint256 planId, uint256 expiryTimestamp, bool isActive) {
        SubscriptionInfo storage sub = userSubscriptions[user];
        planId = sub.planId;
        expiryTimestamp = sub.expiryTimestamp;
        // V2: Active means plan exists, expiry is in the future, AND not currently paused
        isActive = planId != 0 && expiryTimestamp > block.timestamp && sub.pauseStartTime == 0;
    }
}
