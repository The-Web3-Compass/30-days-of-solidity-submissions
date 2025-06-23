// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Proxy contract storing subscription data and delegating logic
contract UpgradeHub {
    // Storage for subscription data (must not change order or type for upgrades)
    address private implementation; // Address of the logic contract
    address private admin; // Admin who can upgrade the contract
    mapping(address => Subscription) private subscriptions; // User subscriptions
    mapping(uint256 => Plan) private plans; // Available subscription plans
    uint256 private planCount; // Total number of plans

    // Structs for subscription and plan data
    struct Subscription {
        uint256 planId; // ID of the subscribed plan
        uint256 startDate; // Subscription start timestamp
        uint256 expiryDate; // Subscription expiry timestamp
        bool isActive; // Subscription status
    }

    struct Plan {
        string name; // Plan name (e.g., Basic, Premium)
        uint256 duration; // Duration in seconds (e.g., 30 days)
        uint256 price; // Price in wei
        bool exists; // Plan existence flag
    }

    // Event emitted when implementation is upgraded
    event Upgraded(address indexed newImplementation);

    // Constructor sets admin and initial implementation
    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }

    // Fallback function delegates calls to the implementation contract
    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "Implementation not set");
        // Perform delegatecall to the implementation
        (bool success, bytes memory data) = impl.delegatecall(msg.data);
        require(success, "Delegatecall failed");
        // Return data from delegatecall
        assembly {
            return(add(data, 0x20), mload(data))
        }
    }

    // Receive function to accept ETH payments
    receive() external payable {}

    // Upgrade the implementation contract (only admin)
    function upgrade(address _newImplementation) external {
        require(msg.sender == admin, "Only admin can upgrade");
        require(_newImplementation != address(0), "Invalid implementation");
        implementation = _newImplementation;
        emit Upgraded(_newImplementation);
    }

    // Get current implementation address
    function getImplementation() external view returns (address) {
        return implementation;
    }

    // Get admin address
    function getAdmin() external view returns (address) {
        return admin;
    }

    // Get plan count (added for logic contract access)
    function getPlanCount() external view returns (uint256) {
        return planCount;
    }

    // Set plan count (internal for logic contract)
    function setPlanCount(uint256 _count) external {
        require(msg.sender == implementation, "Only implementation can set");
        planCount = _count;
    }
}

// Logic contract for subscription management
contract SubscriptionLogic {
    // Storage layout must match UpgradeHub (avoid direct storage writes)
    address private placeholderImplementation; // Align with proxy
    address private placeholderAdmin; // Align with proxy
    mapping(address => UpgradeHub.Subscription) private subscriptions; // Align with proxy
    mapping(uint256 => UpgradeHub.Plan) private plans; // Align with proxy
    uint256 private planCount; // Align with proxy

    // Modifier to check if caller has an active subscription
    modifier onlyActiveSubscriber() {
        UpgradeHub.Subscription storage sub = subscriptions[msg.sender];
        require(
            sub.isActive && block.timestamp < sub.expiryDate,
            "No active subscription"
        );
        _;
    }

    // Add a new subscription plan (admin only)
    function addPlan(
        string memory _name,
        uint256 _duration,
        uint256 _price
    ) external {
        require(
            msg.sender == UpgradeHub(payable(address(this))).getAdmin(),
            "Only admin"
        );
        uint256 planId = UpgradeHub(payable(address(this))).getPlanCount() + 1;
        UpgradeHub.Plan storage plan = plans[planId];
        plan.name = _name;
        plan.duration = _duration;
        plan.price = _price;
        plan.exists = true;
        UpgradeHub(payable(address(this))).setPlanCount(planId);
    }

    // Subscribe to a plan
    function subscribe(uint256 _planId) external payable {
        UpgradeHub.Plan storage plan = plans[_planId];
        require(plan.exists, "Plan does not exist");
        require(msg.value >= plan.price, "Insufficient payment");
        UpgradeHub.Subscription storage sub = subscriptions[msg.sender];
        require(
            !sub.isActive || block.timestamp >= sub.expiryDate,
            "Active subscription exists"
        );
        sub.planId = _planId;
        sub.startDate = block.timestamp;
        sub.expiryDate = block.timestamp + plan.duration;
        sub.isActive = true;
        // Refund excess payment
        if (msg.value > plan.price) {
            payable(msg.sender).transfer(msg.value - plan.price);
        }
    }

    // Upgrade or downgrade subscription plan
    function upgradePlan(
        uint256 _newPlanId
    ) external payable onlyActiveSubscriber {
        UpgradeHub.Plan storage newPlan = plans[_newPlanId];
        require(newPlan.exists, "Plan does not exist");
        require(msg.value >= newPlan.price, "Insufficient payment");
        UpgradeHub.Subscription storage sub = subscriptions[msg.sender];
        sub.planId = _newPlanId;
        sub.expiryDate = block.timestamp + newPlan.duration;
        // Refund excess payment
        if (msg.value > newPlan.price) {
            payable(msg.sender).transfer(msg.value - newPlan.price);
        }
    }

    // Pause subscription (user can pause their own subscription)
    function pauseSubscription() external onlyActiveSubscriber {
        UpgradeHub.Subscription storage sub = subscriptions[msg.sender];
        sub.isActive = false;
    }

    // Resume subscription
    function resumeSubscription() external {
        UpgradeHub.Subscription storage sub = subscriptions[msg.sender];
        require(
            !sub.isActive && block.timestamp < sub.expiryDate,
            "Cannot resume"
        );
        sub.isActive = true;
    }

    // Get subscription details for a user
    function getSubscription(
        address _user
    )
        external
        view
        returns (
            uint256 planId,
            uint256 startDate,
            uint256 expiryDate,
            bool isActive
        )
    {
        UpgradeHub.Subscription storage sub = subscriptions[_user];
        return (sub.planId, sub.startDate, sub.expiryDate, sub.isActive);
    }

    // Get plan details
    function getPlan(
        uint256 _planId
    )
        external
        view
        returns (
            string memory name,
            uint256 duration,
            uint256 price,
            bool exists
        )
    {
        UpgradeHub.Plan storage plan = plans[_planId];
        return (plan.name, plan.duration, plan.price, plan.exists);
    }
}
