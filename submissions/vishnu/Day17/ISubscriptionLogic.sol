// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ISubscriptionLogic
 * @dev Interface for subscription logic contracts
 */
interface ISubscriptionLogic {
    // Plan structure
    struct Plan {
        uint256 planId;
        string name;
        string description;
        uint256 price;        // Price in wei
        uint256 duration;     // Duration in seconds
        uint256 maxUsers;     // Maximum users for this plan
        bool isActive;
        string[] features;    // Array of feature names
    }
    
    // Subscription structure
    struct Subscription {
        uint256 planId;
        address subscriber;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool autoRenewal;
        uint256 renewalCount;
        uint256 totalPaid;
    }
    
    // Logic contract metadata
    function getVersion() external pure returns (uint256);
    function getDescription() external pure returns (string memory);
    
    // Core functions
    function initialize() external;
    function createPlan(
        string calldata name,
        string calldata description,
        uint256 price,
        uint256 duration,
        uint256 maxUsers,
        string[] calldata features
    ) external returns (uint256 planId);
    
    function subscribe(uint256 planId) external payable returns (bool);
    function renewSubscription(uint256 subscriptionId) external payable returns (bool);
    function cancelSubscription(uint256 subscriptionId) external returns (bool);
    function upgradePlan(uint256 subscriptionId, uint256 newPlanId) external payable returns (bool);
}
