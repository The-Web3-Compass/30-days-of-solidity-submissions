// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISubscriptionLogic.sol";

/**
 * @title SubscriptionLogicV1
 * @dev First version of subscription management logic
 */
contract SubscriptionLogicV1 is ISubscriptionLogic {
    // ==================== STORAGE LAYOUT ====================
    // CRITICAL: Must match UpgradeHub storage layout exactly
    
    // Admin and upgrade control (slots 0-2)
    address public admin;
    address public pendingAdmin;
    address public implementation;
    
    // Contract state (slots 3-5)
    bool public paused;
    uint256 public totalPlans;
    uint256 public totalSubscriptions;
    
    // Mappings and dynamic data (slot 6+)
    mapping(uint256 => Plan) public plans;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public userSubscriptions;
    mapping(address => mapping(uint256 => bool)) public hasActivePlan;
    mapping(uint256 => uint256) public planSubscriberCount;
    mapping(address => uint256) public userTotalSpent;
    
    mapping(address => bool) public approvedImplementations;
    address[] public implementationHistory;
    mapping(address => uint256) public implementationVersion;
    
    uint256 public totalRevenue;
    mapping(uint256 => uint256) public planRevenue;
    
    // ==================== CONSTANTS AND IMMUTABLES ====================
    
    uint256 public constant VERSION = 1;
    string public constant DESCRIPTION = "Basic Subscription Management v1.0";
    
    uint256 public constant MIN_PLAN_PRICE = 0.001 ether;
    uint256 public constant MAX_PLAN_PRICE = 100 ether;
    uint256 public constant MIN_DURATION = 1 days;
    uint256 public constant MAX_DURATION = 365 days;
    
    // ==================== EVENTS ====================
    
    event PlanCreated(uint256 indexed planId, string name, uint256 price, uint256 duration);
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address indexed subscriber,
        uint256 indexed planId,
        uint256 amount
    );
    event SubscriptionRenewed(uint256 indexed subscriptionId, uint256 newEndTime);
    event SubscriptionCanceled(uint256 indexed subscriptionId);
    event PlanUpgraded(
        uint256 indexed subscriptionId,
        uint256 indexed oldPlanId,
        uint256 indexed newPlanId
    );
    
    // ==================== MODIFIERS ====================
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "SubscriptionLogicV1: caller is not admin");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "SubscriptionLogicV1: contract is paused");
        _;
    }
    
    modifier validPlan(uint256 planId) {
        require(planId > 0 && planId <= totalPlans, "SubscriptionLogicV1: invalid plan ID");
        require(plans[planId].isActive, "SubscriptionLogicV1: plan is not active");
        _;
    }
    
    modifier validSubscription(uint256 subscriptionId) {
        require(
            subscriptionId > 0 && subscriptionId <= totalSubscriptions,
            "SubscriptionLogicV1: invalid subscription ID"
        );
        _;
    }
    
    // ==================== INTERFACE IMPLEMENTATION ====================
    
    function getVersion() external pure override returns (uint256) {
        return VERSION;
    }
    
    function getDescription() external pure override returns (string memory) {
        return DESCRIPTION;
    }
    
    function initialize() external override {
        // V1 initialization - create default plans
        if (totalPlans == 0) {
            _createInitialPlans();
        }
    }
    
    // ==================== PLAN MANAGEMENT ====================
    
    function createPlan(
        string calldata name,
        string calldata description,
        uint256 price,
        uint256 duration,
        uint256 maxUsers,
        string[] calldata features
    ) external override onlyAdmin returns (uint256 planId) {
        require(bytes(name).length > 0, "SubscriptionLogicV1: name cannot be empty");
        require(price >= MIN_PLAN_PRICE && price <= MAX_PLAN_PRICE, "SubscriptionLogicV1: invalid price");
        require(duration >= MIN_DURATION && duration <= MAX_DURATION, "SubscriptionLogicV1: invalid duration");
        require(maxUsers > 0, "SubscriptionLogicV1: maxUsers must be positive");
        
        planId = ++totalPlans;
        
        plans[planId] = Plan({
            planId: planId,
            name: name,
            description: description,
            price: price,
            duration: duration,
            maxUsers: maxUsers,
            isActive: true,
            features: features
        });
        
        emit PlanCreated(planId, name, price, duration);
    }
    
    function updatePlanStatus(uint256 planId, bool isActive) external onlyAdmin validPlan(planId) {
        plans[planId].isActive = isActive;
    }
    
    function updatePlanPrice(uint256 planId, uint256 newPrice) external onlyAdmin validPlan(planId) {
        require(newPrice >= MIN_PLAN_PRICE && newPrice <= MAX_PLAN_PRICE, "SubscriptionLogicV1: invalid price");
        plans[planId].price = newPrice;
    }
    
    // ==================== SUBSCRIPTION MANAGEMENT ====================
    
    function subscribe(uint256 planId) external payable override whenNotPaused validPlan(planId) returns (bool) {
        Plan memory plan = plans[planId];
        require(msg.value >= plan.price, "SubscriptionLogicV1: insufficient payment");
        require(
            planSubscriberCount[planId] < plan.maxUsers,
            "SubscriptionLogicV1: plan at maximum capacity"
        );
        
        // Check if user already has active subscription for this plan
        require(!hasActivePlan[msg.sender][planId], "SubscriptionLogicV1: already subscribed to this plan");
        
        uint256 subscriptionId = ++totalSubscriptions;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + plan.duration;
        
        subscriptions[subscriptionId] = Subscription({
            planId: planId,
            subscriber: msg.sender,
            startTime: startTime,
            endTime: endTime,
            isActive: true,
            autoRenewal: false,
            renewalCount: 0,
            totalPaid: msg.value
        });
        
        userSubscriptions[msg.sender].push(subscriptionId);
        hasActivePlan[msg.sender][planId] = true;
        planSubscriberCount[planId]++;
        userTotalSpent[msg.sender] += msg.value;
        totalRevenue += msg.value;
        planRevenue[planId] += msg.value;
        
        // Refund excess payment
        if (msg.value > plan.price) {
            payable(msg.sender).transfer(msg.value - plan.price);
        }
        
        emit SubscriptionCreated(subscriptionId, msg.sender, planId, plan.price);
        return true;
    }
    
    function renewSubscription(uint256 subscriptionId) external payable override whenNotPaused validSubscription(subscriptionId) returns (bool) {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(subscription.subscriber == msg.sender, "SubscriptionLogicV1: not subscription owner");
        require(subscription.isActive, "SubscriptionLogicV1: subscription not active");
        
        Plan memory plan = plans[subscription.planId];
        require(plan.isActive, "SubscriptionLogicV1: plan no longer active");
        require(msg.value >= plan.price, "SubscriptionLogicV1: insufficient payment");
        
        // Extend subscription
        if (block.timestamp > subscription.endTime) {
            // Expired - start from now
            subscription.endTime = block.timestamp + plan.duration;
        } else {
            // Still active - extend from current end time
            subscription.endTime += plan.duration;
        }
        
        subscription.renewalCount++;
        subscription.totalPaid += msg.value;
        userTotalSpent[msg.sender] += msg.value;
        totalRevenue += msg.value;
        planRevenue[subscription.planId] += msg.value;
        
        // Refund excess payment
        if (msg.value > plan.price) {
            payable(msg.sender).transfer(msg.value - plan.price);
        }
        
        emit SubscriptionRenewed(subscriptionId, subscription.endTime);
        return true;
    }
    
    function cancelSubscription(uint256 subscriptionId) external override whenNotPaused validSubscription(subscriptionId) returns (bool) {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(
            subscription.subscriber == msg.sender || msg.sender == admin,
            "SubscriptionLogicV1: not authorized to cancel"
        );
        require(subscription.isActive, "SubscriptionLogicV1: subscription already canceled");
        
        subscription.isActive = false;
        hasActivePlan[subscription.subscriber][subscription.planId] = false;
        planSubscriberCount[subscription.planId]--;
        
        emit SubscriptionCanceled(subscriptionId);
        return true;
    }
    
    function upgradePlan(uint256 subscriptionId, uint256 newPlanId) external payable override whenNotPaused validSubscription(subscriptionId) validPlan(newPlanId) returns (bool) {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(subscription.subscriber == msg.sender, "SubscriptionLogicV1: not subscription owner");
        require(subscription.isActive, "SubscriptionLogicV1: subscription not active");
        require(block.timestamp < subscription.endTime, "SubscriptionLogicV1: subscription expired");
        require(newPlanId != subscription.planId, "SubscriptionLogicV1: same plan");
        
        Plan memory oldPlan = plans[subscription.planId];
        Plan memory newPlan = plans[newPlanId];
        
        // Calculate prorated costs
        uint256 remainingTime = subscription.endTime - block.timestamp;
        uint256 oldPlanRefund = (oldPlan.price * remainingTime) / oldPlan.duration;
        uint256 newPlanCost = (newPlan.price * remainingTime) / newPlan.duration;
        
        if (newPlanCost > oldPlanRefund) {
            uint256 additionalCost = newPlanCost - oldPlanRefund;
            require(msg.value >= additionalCost, "SubscriptionLogicV1: insufficient payment for upgrade");
            
            // Refund excess
            if (msg.value > additionalCost) {
                payable(msg.sender).transfer(msg.value - additionalCost);
            }
        } else {
            // Refund difference
            uint256 refund = oldPlanRefund - newPlanCost;
            payable(msg.sender).transfer(refund);
        }
        
        // Update subscription
        uint256 oldPlanId = subscription.planId;
        subscription.planId = newPlanId;
        
        // Update plan tracking
        hasActivePlan[msg.sender][oldPlanId] = false;
        hasActivePlan[msg.sender][newPlanId] = true;
        planSubscriberCount[oldPlanId]--;
        planSubscriberCount[newPlanId]++;
        
        emit PlanUpgraded(subscriptionId, oldPlanId, newPlanId);
        return true;
    }
    
    // ==================== VIEW FUNCTIONS ====================
    
    function getPlan(uint256 planId) external view returns (Plan memory) {
        require(planId > 0 && planId <= totalPlans, "SubscriptionLogicV1: invalid plan ID");
        return plans[planId];
    }
    
    function getSubscription(uint256 subscriptionId) external view returns (Subscription memory) {
        require(subscriptionId > 0 && subscriptionId <= totalSubscriptions, "SubscriptionLogicV1: invalid subscription ID");
        return subscriptions[subscriptionId];
    }
    
    function getUserSubscriptions(address user) external view returns (uint256[] memory) {
        return userSubscriptions[user];
    }
    
    function getUserActiveSubscriptions(address user) external view returns (uint256[] memory activeIds) {
        uint256[] memory allSubs = userSubscriptions[user];
        uint256[] memory temp = new uint256[](allSubs.length);
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < allSubs.length; i++) {
            Subscription memory sub = subscriptions[allSubs[i]];
            if (sub.isActive && block.timestamp < sub.endTime) {
                temp[activeCount] = allSubs[i];
                activeCount++;
            }
        }
        
        activeIds = new uint256[](activeCount);
        for (uint256 i = 0; i < activeCount; i++) {
            activeIds[i] = temp[i];
        }
    }
    
    function isSubscriptionActive(uint256 subscriptionId) external view returns (bool) {
        if (subscriptionId == 0 || subscriptionId > totalSubscriptions) return false;
        
        Subscription memory subscription = subscriptions[subscriptionId];
        return subscription.isActive && block.timestamp < subscription.endTime;
    }
    
    function getContractStats() external view returns (
        uint256 plansCount,
        uint256 subscriptionsCount,
        uint256 revenue,
        uint256 activeSubscriptions
    ) {
        plansCount = totalPlans;
        subscriptionsCount = totalSubscriptions;
        revenue = totalRevenue;
        
        // Count active subscriptions
        for (uint256 i = 1; i <= totalSubscriptions; i++) {
            Subscription memory sub = subscriptions[i];
            if (sub.isActive && block.timestamp < sub.endTime) {
                activeSubscriptions++;
            }
        }
    }
    
    // ==================== INTERNAL FUNCTIONS ====================
    
    function _createInitialPlans() internal {
        // Create basic plans
        string[] memory basicFeatures = new string[](2);
        basicFeatures[0] = "Basic Support";
        basicFeatures[1] = "5GB Storage";
        
        plans[++totalPlans] = Plan({
            planId: totalPlans,
            name: "Basic",
            description: "Basic subscription plan",
            price: 0.01 ether,
            duration: 30 days,
            maxUsers: 1000,
            isActive: true,
            features: basicFeatures
        });
        
        string[] memory premiumFeatures = new string[](4);
        premiumFeatures[0] = "Priority Support";
        premiumFeatures[1] = "50GB Storage";
        premiumFeatures[2] = "Advanced Analytics";
        premiumFeatures[3] = "API Access";
        
        plans[++totalPlans] = Plan({
            planId: totalPlans,
            name: "Premium",
            description: "Premium subscription plan",
            price: 0.05 ether,
            duration: 30 days,
            maxUsers: 500,
            isActive: true,
            features: premiumFeatures
        });
    }
}
