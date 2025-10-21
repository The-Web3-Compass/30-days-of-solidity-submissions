// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISubscriptionManager
 * @author shivam
 * @notice Interface defining the functions for managing user subscriptions in the SaaS dApp.
 * @dev Ensures different logic contract versions adhere to a common external API.
 */
interface ISubscriptionManager {
    /**
     * @notice Emitted when a new subscription plan is added.
     * @param planId The unique identifier for the new plan.
     * @param name The name of the plan.
     * @param duration The duration of the plan in seconds.
     */
    event PlanAdded(uint256 indexed planId, string name, uint256 duration);

    /**
     * @notice Emitted when a user subscribes to a plan.
     * @param user The address of the subscriber.
     * @param planId The ID of the plan subscribed to.
     * @param expiryTimestamp The timestamp when the subscription expires.
     */
    event Subscribed(address indexed user, uint256 indexed planId, uint256 expiryTimestamp);

    /**
     * @notice Emitted when a user upgrades their subscription plan.
     * @param user The address of the user upgrading.
     * @param oldPlanId The ID of the previous plan.
     * @param newPlanId The ID of the new plan.
     * @param newExpiryTimestamp The new expiry timestamp after upgrading.
     */
    event SubscriptionUpgraded(address indexed user, uint256 indexed oldPlanId, uint256 indexed newPlanId, uint256 newExpiryTimestamp);

    /**
     * @notice Emitted when a user's subscription is paused (in V2+).
     * @param user The address of the user whose subscription is paused.
     * @param pauseStartTime The timestamp when the pause began.
     */
    event SubscriptionPaused(address indexed user, uint256 pauseStartTime);

    /**
     * @notice Emitted when a user's subscription is resumed (in V2+).
     * @param user The address of the user whose subscription is resumed.
     * @param newExpiryTimestamp The adjusted expiry timestamp after resuming.
     */
    event SubscriptionResumed(address indexed user, uint256 newExpiryTimestamp);

    /**
     * @notice Adds a new subscription plan available for users.
     * @dev Only callable by the owner. Emits {PlanAdded}.
     * @param name The descriptive name of the plan (e.g., "Basic", "Pro").
     * @param duration The duration of the subscription period in seconds.
     */
    function addPlan(string calldata name, uint256 duration) external;

    /**
     * @notice Subscribes the calling user to a specific plan.
     * @dev Assumes payment is handled externally or implicitly (e.g., free tier).
     * @dev Reverts if the plan ID is invalid or the user is already actively subscribed. Emits {Subscribed}.
     * @param planId The ID of the plan to subscribe to.
     */
    function subscribe(uint256 planId) external;

    /**
     * @notice Upgrades the calling user's current subscription to a new plan.
     * @dev Reverts if the user is not currently subscribed or the new plan ID is invalid.
     * @dev Resets the subscription duration based on the new plan. Emits {SubscriptionUpgraded}.
     * @param newPlanId The ID of the plan to upgrade to.
     */
    function upgradeSubscription(uint256 newPlanId) external;

    /**
     * @notice Retrieves the details of a specific subscription plan.
     * @param planId The ID of the plan.
     * @return name The name of the plan.
     * @return duration The duration of the plan in seconds.
     */
    function getPlan(uint256 planId) external view returns (string memory name, uint256 duration);

    /**
     * @notice Retrieves the subscription details for a given user.
     * @param user The address of the user.
     * @return planId The ID of the user's current plan (0 if none).
     * @return expiryTimestamp The timestamp when the subscription expires (0 if none).
     * @return isActive True if the subscription is current and not expired, false otherwise.
     */
    function getSubscription(address user) external view returns (uint256 planId, uint256 expiryTimestamp, bool isActive);

    /**
     * @notice Retrieves the total number of plans added.
     * @return count The number of plans.
     */
    function planCount() external view returns (uint256 count);

    // --- V2 Functions ---

    /**
     * @notice Pauses the calling user's current active subscription. (V2 Functionality)
     * @dev Reverts if the user is not subscribed or already paused. Emits {SubscriptionPaused}.
     * @dev The expiry date will be extended by the pause duration upon resuming.
     */
    function pauseSubscription() external;

    /**
     * @notice Resumes the calling user's paused subscription. (V2 Functionality)
     * @dev Reverts if the user is not subscribed or not currently paused. Emits {SubscriptionResumed}.
     * @dev Adjusts the expiry date to account for the time paused.
     */
    function resumeSubscription() external;

    /**
     * @notice Checks if a user's subscription is currently paused. (V2 Functionality)
     * @param user The address of the user to check.
     * @return isPaused_ True if the subscription is paused, false otherwise.
     */
    function isPaused(address user) external view returns (bool isPaused_);
}
