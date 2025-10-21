// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Proxy Contract (Storage Layer)
contract SubscriptionProxy {
    // EIP-1967 storage slots
    bytes32 private constant _IMPLEMENTATION_SLOT = 
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _ADMIN_SLOT = 
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address logicAddress, address adminAddress, bytes memory data) {
        _setAdmin(adminAddress);
        _setImplementation(logicAddress);
        if(data.length > 0) {
            (bool success,) = logicAddress.delegatecall(data);
            require(success, "Initialization failed");
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Not admin");
        _;
    }

    function _getAdmin() private view returns (address adminAddress) {
        assembly {
            adminAddress := sload(_ADMIN_SLOT)
        }
    }

    function _setAdmin(address adminAddress) private {
        assembly {
            sstore(_ADMIN_SLOT, adminAddress)
        }
    }

    function _getImplementation() private view returns (address impl) {
        assembly {
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function _setImplementation(address newImplementation) private {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function upgradeTo(address newImplementation) external onlyAdmin {
        _setImplementation(newImplementation);
    }

    function admin() external view onlyAdmin returns (address) {
        return _getAdmin();
    }

    function implementation() external view onlyAdmin returns (address) {
        return _getImplementation();
    }

    // Fallback handles all logic calls
    fallback() external payable {
        address impl = _getImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}

// Logic Contract (Version 1)
contract SubscriptionLogicV1 {
    // Storage slot must match proxy layout
    bytes32 constant SUBSCRIPTION_STORAGE_SLOT = 
        keccak256("subscription.manager.storage");
    
    struct Subscription {
        uint256 planId;
        uint256 startDate;
        uint256 renewalDate;
        bool isPaused;
    }

    struct SubscriptionStorage {
        address owner;
        bool initialized;
        mapping(uint256 => Plan) plans;
        mapping(address => Subscription) userSubscriptions;
        mapping(address => bool) billingManagers;
    }
    
    struct Plan {
        uint256 price;
        uint256 duration;
        bool isActive;
    }
    
    event Subscribed(address user, uint256 planId, uint256 renewalDate);
    event PlanAdded(uint256 planId, uint256 price, uint256 duration);
    event Upgraded(address newImplementation);

    function _subscriptionStorage() internal pure returns (SubscriptionStorage storage s) {
        bytes32 slot = SUBSCRIPTION_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    // Initializer (called through proxy constructor)
    function initialize(address admin) external {
        SubscriptionStorage storage s = _subscriptionStorage();
        require(!s.initialized, "Already initialized");
        s.initialized = true;
        s.owner = admin;
        s.billingManagers[admin] = true;
        
        // Initialize default plans
        s.plans[1] = Plan(0.1 ether, 30 days, true);
        s.plans[2] = Plan(0.3 ether, 90 days, true);
    }

    modifier onlyOwner() {
        require(_subscriptionStorage().owner == msg.sender, "Not owner");
        _;
    }

    modifier onlyBillingManager() {
        require(_subscriptionStorage().billingManagers[msg.sender], "Not billing manager");
        _;
    }

    function subscribe(uint256 planId) external payable {
        SubscriptionStorage storage s = _subscriptionStorage();
        Plan memory plan = s.plans[planId];
        
        require(plan.isActive, "Plan inactive");
        require(msg.value >= plan.price, "Insufficient payment");
        
        Subscription storage sub = s.userSubscriptions[msg.sender];
        sub.planId = planId;
        sub.startDate = block.timestamp;
        sub.renewalDate = block.timestamp + plan.duration;
        sub.isPaused = false;
        
        emit Subscribed(msg.sender, planId, sub.renewalDate);
    }

    function renewSubscription(address user) external payable virtual {
        SubscriptionStorage storage s = _subscriptionStorage();
        Subscription storage sub = s.userSubscriptions[user];
        Plan memory plan = s.plans[sub.planId];
        
        require(!sub.isPaused, "Subscription paused");
        require(block.timestamp >= sub.renewalDate - 7 days, "Too early to renew");
        require(msg.value >= plan.price, "Insufficient payment");
        
        sub.renewalDate += plan.duration;
    }

    // Admin functions
    function addBillingManager(address manager) external onlyOwner {
        _subscriptionStorage().billingManagers[manager] = true;
    }

    function addPlan(uint256 price, uint256 duration) external onlyOwner {
        SubscriptionStorage storage s = _subscriptionStorage();
        uint256 planId = uint256(keccak256(abi.encode(price, duration, block.timestamp)));
        s.plans[planId] = Plan(price, duration, true);
        emit PlanAdded(planId, price, duration);
    }

    function pauseUserSubscription(address user) external onlyBillingManager {
        Subscription storage sub = _subscriptionStorage().userSubscriptions[user];
        require(sub.renewalDate > 0, "No subscription");
        sub.isPaused = true;
    }

    function withdrawFunds(address payable recipient) external onlyOwner {
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}

// Logic Contract (Version 2 - Upgrade)
contract SubscriptionLogicV2 is SubscriptionLogicV1 {
    // New functionality - discounts for long-term plans
    function applyDiscount(uint256 planId, uint256 discountPercent) external onlyOwner {
        require(discountPercent <= 50, "Discount too high");
        SubscriptionStorage storage s = _subscriptionStorage();
        Plan storage plan = s.plans[planId];
        
        uint256 originalPrice = plan.price * 100 / (100 - discountPercent);
        plan.price = originalPrice * (100 - discountPercent) / 100;
    }

    // Enhanced renewal with grace period
    function renewSubscription(address user) external payable override {
        SubscriptionStorage storage s = _subscriptionStorage();
        Subscription storage sub = s.userSubscriptions[user];
        Plan memory plan = s.plans[sub.planId];
        
        require(!sub.isPaused, "Subscription paused");
        require(
            block.timestamp >= sub.renewalDate - 7 days || 
            block.timestamp <= sub.renewalDate + 3 days,
            "Outside renewal window"
        );
        require(msg.value >= plan.price, "Insufficient payment");
        
        // Reset grace period if expired
        if(block.timestamp > sub.renewalDate) {
            sub.renewalDate = block.timestamp + plan.duration;
        } else {
            sub.renewalDate += plan.duration;
        }
    }
}