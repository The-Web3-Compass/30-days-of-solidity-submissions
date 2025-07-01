/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionProxy {
    address public implementation;
    address public admin;
    
    struct Subscription {
        uint256 planId;
        uint256 startDate;
        uint256 expiryDate;
        bool isPaused;
    }
    
    mapping(address => Subscription) public subscriptions;
    mapping(uint256 => uint256) public planPrices;
    mapping(uint256 => string) public planNames;
    
    event Upgraded(address indexed newImplementation);
    event Subscribed(address indexed user, uint256 planId, uint256 expiryDate);
    event Renewed(address indexed user, uint256 expiryDate);
    event PlanAdded(uint256 planId, string name, uint256 price);
    event AccountPaused(address indexed user, bool paused);
    
    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }
    
    function upgradeTo(address newImplementation) external onlyAdmin {
        implementation = newImplementation;
        emit Upgraded(newImplementation);
    }
    
    fallback() external payable {
        address _impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}

contract SubscriptionLogicV1 {
    address public implementation;
    address public admin;
    
    struct Subscription {
        uint256 planId;
        uint256 startDate;
        uint256 expiryDate;
        bool isPaused;
    }
    
    mapping(address => Subscription) public subscriptions;
    mapping(uint256 => uint256) public planPrices;
    mapping(uint256 => string) public planNames;
    
    event Subscribed(address indexed user, uint256 planId, uint256 expiryDate);
    event Renewed(address indexed user, uint256 expiryDate);
    event PlanAdded(uint256 planId, string name, uint256 price);
    
    function initialize() external {
        require(admin == address(0), "Already initialized");
        admin = msg.sender;
        
        addPlan(1, "Basic", 0.01 ether);
        addPlan(2, "Pro", 0.03 ether);
        addPlan(3, "Enterprise", 0.1 ether);
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }
    
    function subscribe(uint256 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");
        require(subscriptions[msg.sender].expiryDate < block.timestamp, "Active subscription");
        
        uint256 expiry = block.timestamp + 30 days;
        subscriptions[msg.sender] = Subscription(planId, block.timestamp, expiry, false);
        
        emit Subscribed(msg.sender, planId, expiry);
    }
    
    function renew() external payable {
        Subscription storage sub = subscriptions[msg.sender];
        require(sub.expiryDate > 0, "No subscription");
        require(msg.value >= planPrices[sub.planId], "Insufficient payment");
        
        sub.expiryDate += 30 days;
        emit Renewed(msg.sender, sub.expiryDate);
    }
    
    function addPlan(uint256 planId, string memory name, uint256 price) public onlyAdmin {
        planPrices[planId] = price;
        planNames[planId] = name;
        emit PlanAdded(planId, name, price);
    }
    
    function getUserSubscription(address user) external view returns (
        uint256 planId, 
        string memory planName,
        uint256 startDate,
        uint256 expiryDate,
        bool isPaused
    ) {
        Subscription memory sub = subscriptions[user];
        return (sub.planId, planNames[sub.planId], sub.startDate, sub.expiryDate, sub.isPaused);
    }
}

contract SubscriptionLogicV2 {
    address public implementation;
    address public admin;
    
    struct Subscription {
        uint256 planId;
        uint256 startDate;
        uint256 expiryDate;
        bool isPaused;
    }
    
    mapping(address => Subscription) public subscriptions;
    mapping(uint256 => uint256) public planPrices;
    mapping(uint256 => string) public planNames;
    
    event Subscribed(address indexed user, uint256 planId, uint256 expiryDate);
    event Renewed(address indexed user, uint256 expiryDate);
    event PlanAdded(uint256 planId, string name, uint256 price);
    event AccountPaused(address indexed user, bool paused);
    
    function initialize() external {
        require(admin == address(0), "Already initialized");
        admin = msg.sender;
        
        addPlan(1, "Basic", 0.01 ether);
        addPlan(2, "Pro", 0.03 ether);
        addPlan(3, "Enterprise", 0.1 ether);
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }
    
    function subscribe(uint256 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");
        require(subscriptions[msg.sender].expiryDate < block.timestamp, "Active subscription");
        
        uint256 expiry = block.timestamp + 30 days;
        subscriptions[msg.sender] = Subscription(planId, block.timestamp, expiry, false);
        
        emit Subscribed(msg.sender, planId, expiry);
    }
    
    function renew() external payable {
        Subscription storage sub = subscriptions[msg.sender];
        require(sub.expiryDate > 0, "No subscription");
        require(msg.value >= planPrices[sub.planId], "Insufficient payment");
        
        sub.expiryDate += 30 days;
        emit Renewed(msg.sender, sub.expiryDate);
    }
    
    function addPlan(uint256 planId, string memory name, uint256 price) public onlyAdmin {
        planPrices[planId] = price;
        planNames[planId] = name;
        emit PlanAdded(planId, name, price);
    }
    
    function pauseAccount(address user, bool pause) external onlyAdmin {
        require(subscriptions[user].expiryDate > 0, "No subscription");
        subscriptions[user].isPaused = pause;
        emit AccountPaused(user, pause);
    }
    
    function upgradePlan(address user, uint256 newPlanId) external payable {
        Subscription storage sub = subscriptions[user];
        require(sub.expiryDate > block.timestamp, "Subscription expired");
        require(!sub.isPaused, "Account paused");
        require(planPrices[newPlanId] > planPrices[sub.planId], "Invalid upgrade");
        
        uint256 priceDifference = planPrices[newPlanId] - planPrices[sub.planId];
        require(msg.value >= priceDifference, "Insufficient payment");
        
        uint256 remainingDays = (sub.expiryDate - block.timestamp) / 1 days;
        sub.planId = newPlanId;
        sub.expiryDate = block.timestamp + remainingDays * 1 days;
        
        emit Subscribed(user, newPlanId, sub.expiryDate);
    }
    
    function getUserSubscription(address user) external view returns (
        uint256 planId, 
        string memory planName,
        uint256 startDate,
        uint256 expiryDate,
        bool isPaused
    ) {
        Subscription memory sub = subscriptions[user];
        return (sub.planId, planNames[sub.planId], sub.startDate, sub.expiryDate, sub.isPaused);
    }
}
