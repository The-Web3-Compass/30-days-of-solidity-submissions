// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISubscriptionLogic.sol";

/**
 * @title SubscriptionLogicV2
 * @dev Optimized version with essential V2 features only
 */
contract SubscriptionLogicV2 is ISubscriptionLogic {
    // ==================== STORAGE LAYOUT (MUST MATCH V1) ====================
    
    address public admin;
    address public pendingAdmin;
    address public implementation;
    
    bool public paused;
    uint256 public totalPlans;
    uint256 public totalSubscriptions;
    
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
    
    // ==================== NEW STORAGE (V2 ADDITIONS) ====================
    
    mapping(address => uint256) public loyaltyPoints;
    mapping(uint256 => uint256) public planDiscounts;
    mapping(address => bool) public autoRenewalEnabled;
    uint256 public referralBonus;
    
    // ==================== CONSTANTS ====================
    
    uint256 public constant VERSION = 2;
    string public constant DESCRIPTION = "Enhanced Subscription Management v2.0";
    
    uint256 public constant MIN_PLAN_PRICE = 0.001 ether;
    uint256 public constant MAX_PLAN_PRICE = 100 ether;
    uint256 public constant MIN_DURATION = 1 days;
    uint256 public constant MAX_DURATION = 365 days;
    uint256 public constant LOYALTY_POINTS_PER_ETHER = 1000;
    uint256 public constant BASIS_POINTS = 10000;
    
    // ==================== EVENTS ====================
    
    event AutoRenewalEnabled(address indexed user);
    event LoyaltyPointsAwarded(address indexed user, uint256 points);
    event DiscountApplied(address indexed user, uint256 planId, uint256 discount);
    event PlanCreated(uint256 indexed planId, string name, uint256 price, uint256 duration);
    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed subscriber, uint256 indexed planId, uint256 amount);
    event SubscriptionRenewed(uint256 indexed subscriptionId, uint256 newEndTime);
    event SubscriptionCanceled(uint256 indexed subscriptionId);
    event PlanUpgraded(uint256 indexed subscriptionId, uint256 indexed oldPlanId, uint256 indexed newPlanId);
    
    // ==================== MODIFIERS ====================
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }
    
    modifier validPlan(uint256 planId) {
        require(planId > 0 && planId <= totalPlans && plans[planId].isActive, "Invalid plan");
        _;
    }
    
    modifier validSubscription(uint256 subscriptionId) {
        require(subscriptionId > 0 && subscriptionId <= totalSubscriptions, "Invalid subscription");
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
        if (referralBonus == 0) {
            referralBonus = 500; // 5%
        }
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
        require(bytes(name).length > 0 && price >= MIN_PLAN_PRICE && price <= MAX_PLAN_PRICE, "Invalid params");
        require(duration >= MIN_DURATION && duration <= MAX_DURATION && maxUsers > 0, "Invalid params");
        
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
    
    // ==================== SUBSCRIPTION MANAGEMENT ====================
    
    function subscribe(uint256 planId) external payable override whenNotPaused validPlan(planId) returns (bool) {
        Plan memory plan = plans[planId];
        require(planSubscriberCount[planId] < plan.maxUsers && !hasActivePlan[msg.sender][planId], "Cannot subscribe");
        
        uint256 discount = planDiscounts[planId];
        uint256 finalPrice = discount > 0 ? plan.price - (plan.price * discount / BASIS_POINTS) : plan.price;
        require(msg.value >= finalPrice, "Insufficient payment");
        
        uint256 subscriptionId = ++totalSubscriptions;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + plan.duration;
        
        subscriptions[subscriptionId] = Subscription({
            planId: planId,
            subscriber: msg.sender,
            startTime: startTime,
            endTime: endTime,
            isActive: true,
            autoRenewal: autoRenewalEnabled[msg.sender],
            renewalCount: 0,
            totalPaid: finalPrice
        });
        
        userSubscriptions[msg.sender].push(subscriptionId);
        hasActivePlan[msg.sender][planId] = true;
        planSubscriberCount[planId]++;
        userTotalSpent[msg.sender] += finalPrice;
        totalRevenue += finalPrice;
        planRevenue[planId] += finalPrice;
        
        // Award loyalty points
        loyaltyPoints[msg.sender] += (finalPrice / 1 ether) * LOYALTY_POINTS_PER_ETHER;
        
        if (msg.value > finalPrice) {
            payable(msg.sender).transfer(msg.value - finalPrice);
        }
        
        emit SubscriptionCreated(subscriptionId, msg.sender, planId, finalPrice);
        return true;
    }
    
    function renewSubscription(uint256 subscriptionId) external payable override whenNotPaused validSubscription(subscriptionId) returns (bool) {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(subscription.subscriber == msg.sender && subscription.isActive, "Not authorized or inactive");
        
        Plan memory plan = plans[subscription.planId];
        require(plan.isActive, "Plan inactive");
        
        uint256 finalPrice = _calculateDiscountedPrice(msg.sender, plan.price);
        require(msg.value >= finalPrice, "Insufficient payment");
        
        if (block.timestamp > subscription.endTime) {
            subscription.endTime = block.timestamp + plan.duration;
        } else {
            subscription.endTime += plan.duration;
        }
        
        subscription.renewalCount++;
        subscription.totalPaid += finalPrice;
        userTotalSpent[msg.sender] += finalPrice;
        totalRevenue += finalPrice;
        planRevenue[subscription.planId] += finalPrice;
        
        loyaltyPoints[msg.sender] += (finalPrice / 1 ether) * LOYALTY_POINTS_PER_ETHER;
        
        if (msg.value > finalPrice) {
            payable(msg.sender).transfer(msg.value - finalPrice);
        }
        
        emit SubscriptionRenewed(subscriptionId, subscription.endTime);
        return true;
    }
    
    function cancelSubscription(uint256 subscriptionId) external override whenNotPaused validSubscription(subscriptionId) returns (bool) {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(subscription.subscriber == msg.sender || msg.sender == admin, "Not authorized");
        require(subscription.isActive, "Already canceled");
        
        subscription.isActive = false;
        hasActivePlan[subscription.subscriber][subscription.planId] = false;
        planSubscriberCount[subscription.planId]--;
        
        emit SubscriptionCanceled(subscriptionId);
        return true;
    }
    
    function upgradePlan(uint256 subscriptionId, uint256 newPlanId) external payable override whenNotPaused validSubscription(subscriptionId) validPlan(newPlanId) returns (bool) {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(subscription.subscriber == msg.sender && subscription.isActive, "Not authorized or inactive");
        require(block.timestamp < subscription.endTime && newPlanId != subscription.planId, "Cannot upgrade");
        
        Plan memory oldPlan = plans[subscription.planId];
        Plan memory newPlan = plans[newPlanId];
        
        uint256 remainingTime = subscription.endTime - block.timestamp;
        uint256 oldRefund = (oldPlan.price * remainingTime) / oldPlan.duration;
        uint256 newCost = (_calculateDiscountedPrice(msg.sender, newPlan.price) * remainingTime) / newPlan.duration;
        
        if (newCost > oldRefund) {
            uint256 additional = newCost - oldRefund;
            require(msg.value >= additional, "Insufficient payment");
            if (msg.value > additional) {
                payable(msg.sender).transfer(msg.value - additional);
            }
        } else {
            payable(msg.sender).transfer(oldRefund - newCost);
        }
        
        uint256 oldPlanId = subscription.planId;
        subscription.planId = newPlanId;
        
        hasActivePlan[msg.sender][oldPlanId] = false;
        hasActivePlan[msg.sender][newPlanId] = true;
        planSubscriberCount[oldPlanId]--;
        planSubscriberCount[newPlanId]++;
        
        emit PlanUpgraded(subscriptionId, oldPlanId, newPlanId);
        return true;
    }
    
    // ==================== V2 FEATURES ====================
    
    function enableAutoRenewal() external {
        autoRenewalEnabled[msg.sender] = true;
        emit AutoRenewalEnabled(msg.sender);
    }
    
    function disableAutoRenewal() external {
        autoRenewalEnabled[msg.sender] = false;
    }
    
    function setPlanDiscount(uint256 planId, uint256 discountBasisPoints) external onlyAdmin validPlan(planId) {
        require(discountBasisPoints <= 5000, "Discount too high");
        planDiscounts[planId] = discountBasisPoints;
    }
    
    // ==================== VIEW FUNCTIONS ====================
    
    function getPlan(uint256 planId) external view returns (Plan memory) {
        require(planId > 0 && planId <= totalPlans, "Invalid plan");
        return plans[planId];
    }
    
    function getSubscription(uint256 subscriptionId) external view returns (Subscription memory) {
        require(subscriptionId > 0 && subscriptionId <= totalSubscriptions, "Invalid subscription");
        return subscriptions[subscriptionId];
    }
    
    function getUserSubscriptions(address user) external view returns (uint256[] memory) {
        return userSubscriptions[user];
    }
    
    function isSubscriptionActive(uint256 subscriptionId) external view returns (bool) {
        if (subscriptionId == 0 || subscriptionId > totalSubscriptions) return false;
        Subscription memory sub = subscriptions[subscriptionId];
        return sub.isActive && block.timestamp < sub.endTime;
    }
    
    function getUserLoyaltyInfo(address user) external view returns (uint256 points, uint256 totalSpent, bool autoRenew) {
        return (loyaltyPoints[user], userTotalSpent[user], autoRenewalEnabled[user]);
    }
    
    // ==================== INTERNAL FUNCTIONS ====================
    
    function _calculateDiscountedPrice(address user, uint256 basePrice) internal view returns (uint256) {
        uint256 userLoyalty = loyaltyPoints[user];
        if (userLoyalty < 1000) return basePrice;
        
        uint256 discountPercent = userLoyalty / 1000;
        if (discountPercent > 20) discountPercent = 20;
        
        return basePrice - (basePrice * discountPercent / 100);
    }
    
    function _createInitialPlans() internal {
        string[] memory basicFeatures = new string[](2);
        basicFeatures[0] = "Basic Support";
        basicFeatures[1] = "10GB Storage";
        
        plans[++totalPlans] = Plan({
            planId: totalPlans,
            name: "Basic Plus",
            description: "Enhanced basic plan",
            price: 0.01 ether,
            duration: 30 days,
            maxUsers: 1000,
            isActive: true,
            features: basicFeatures
        });
        
        string[] memory premiumFeatures = new string[](3);
        premiumFeatures[0] = "Priority Support";
        premiumFeatures[1] = "100GB Storage";
        premiumFeatures[2] = "API Access";
        
        plans[++totalPlans] = Plan({
            planId: totalPlans,
            name: "Premium Plus",
            description: "Enhanced premium plan",
            price: 0.05 ether,
            duration: 30 days,
            maxUsers: 500,
            isActive: true,
            features: premiumFeatures
        });
    }
}
