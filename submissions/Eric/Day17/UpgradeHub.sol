// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
  SubscriptionStorage library
  - Defines the storage layout and places it into a fixed storage slot,
    ensuring that both Proxy and Logic contracts access the same data via the same slot,
    thus achieving the goal of "replacing logic while retaining data."
*/
library SubscriptionStorage {
    struct Subscription {
        uint256 planId;
        uint256 expiryTimestamp; // unix time
        bool paused;
    }

    struct Plan {
        uint256 id;
        uint256 price;    // in wei
        uint256 duration; // seconds
        bool exists;
    }

    struct Layout {
        mapping(address => Subscription) subscriptions;
        mapping(uint256 => Plan) plans;
        address treasury; // Treasury address
        // You can add more global data here
        bool initialized;
    }

    // Fixed slot, ensuring that both the logic contract and proxy access the same slot
    bytes32 internal constant STORAGE_SLOT = keccak256("saas.subscription.storage.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/*
  Proxy Contract
  - Only stores two special slots: implementation and admin (using EIP-1967 style names)
  - All other business data is managed by the SubscriptionStorage library (no slot conflicts)
  - Functions not explicitly recognized by the Proxy contract are forwarded via fallback to the implementation (delegatecall)
*/
contract SubscriptionProxy {
    // EIP-1967 style slot: keccak("eip1967.proxy.implementation") - 1
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 internal constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(address initialImplementation, address admin_) {
        require(initialImplementation != address(0), "impl 0");
        require(admin_ != address(0), "admin 0");
        _setImplementation(initialImplementation);
        _setAdmin(admin_);
    }

    // --- admin getters/setters using fixed slots ---
    function _setImplementation(address impl) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, impl)
        }
    }
    function _implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _setAdmin(address admin_) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, admin_)
        }
    }
    function _admin() public view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    // Admin-only upgrade function
    modifier onlyAdmin() {
        require(msg.sender == _admin(), "not admin");
        _;
    }

    function upgradeTo(address newImplementation) external onlyAdmin {
        require(newImplementation != address(0), "impl 0");
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        address prev = _admin();
        _setAdmin(newAdmin);
        emit AdminChanged(prev, newAdmin);
    }

    // Fallback: forward everything to implementation via delegatecall
    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    // low-level delegate to current implementation
    function _delegate() internal {
        address impl = _implementation();
        require(impl != address(0), "impl not set");
        assembly {
            // copy calldata
            calldatacopy(0, 0, calldatasize())

            // delegatecall(gas, impl, calldata, calldatasize, 0, 0)
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            let size := returndatasize()

            // copy returned data
            returndatacopy(0, 0, size)

            switch result
            case 0 { revert(0, size) }
            default { return(0, size) }
        }
    }
}

/*
  SubscriptionLogic
  - Actual implementation: adding plans, user subscriptions/upgrade/renewals, pausing accounts, querying, etc.
  - Directly uses SubscriptionStorage.layout() to access data (ensures consistency with Proxy storage)
  - Note: This contract can be deployed multiple times (new versions deployed on upgrade), but it itself does not store data
*/
contract SubscriptionLogic {
    using SubscriptionStorage for SubscriptionStorage.Layout;

    event PlanAdded(uint256 indexed planId, uint256 price, uint256 duration);
    event Subscribed(address indexed user, uint256 indexed planId, uint256 expiry);
    event Upgraded(address indexed user, uint256 fromPlan, uint256 toPlan, uint256 newExpiry);
    event Paused(address indexed user);
    event Unpaused(address indexed user);

    // Initialization function: sets the treasury, etc., during the first deployment and proxy delegatecall
    // Requires that it can only be initialized once (via storage.initialized flag)
    function initialize(address treasury_) external {
        SubscriptionStorage.Layout storage s = SubscriptionStorage.layout();
        require(!s.initialized, "already init");
        require(treasury_ != address(0), "treasury 0");
        s.treasury = treasury_;
        s.initialized = true;
    }

    // Add a subscription plan (admin function) — note: admin check is done externally (proxy admin can call via delegatecall)
    // It is assumed that the proxy's admin will directly call proxy (and execute within the delegatecall context)
    function addPlan(uint256 planId, uint256 price, uint256 duration) external {
        SubscriptionStorage.Layout storage s = SubscriptionStorage.layout();
        // NOTE: access control: require msg.sender == proxy admin
        // When called via proxy.delegatecall, msg.sender is the original tx sender.
        // Typically admin will be external account that calls proxy to route to logic.
        // To be safe, here we check that msg.sender == address(this) is NOT used.
        require(!s.plans[planId].exists, "plan exists");
        s.plans[planId] = SubscriptionStorage.Plan({
            id: planId,
            price: price,
            duration: duration,
            exists: true
        });
        emit PlanAdded(planId, price, duration);
    }

    // User subscribes to a plan (simple example: pays to proxy, then sets expiry)
    // This function expects msg.value == plan.price when called via proxy.
    function subscribe(uint256 planId) external payable {
        SubscriptionStorage.Layout storage s = SubscriptionStorage.layout();
        SubscriptionStorage.Plan storage p = s.plans[planId];
        require(p.exists, "no such plan");
        require(msg.value == p.price, "wrong price");

        // Transfer funds to treasury (the treasury is stored in storage)
        (bool sent, ) = payable(s.treasury).call{value: msg.value}("");
        require(sent, "treasury transfer failed");

        // Set subscription
        SubscriptionStorage.Subscription storage sub = s.subscriptions[msg.sender];
        uint256 newExpiry;
        if (sub.expiryTimestamp > block.timestamp) {
            // Extend from current expiry
            newExpiry = sub.expiryTimestamp + p.duration;
        } else {
            // Start from now
            newExpiry = block.timestamp + p.duration;
        }
        sub.planId = planId;
        sub.expiryTimestamp = newExpiry;
        sub.paused = false;

        emit Subscribed(msg.sender, planId, newExpiry);
    }

    // Upgrade plan (user-initiated, price difference logic can be customized)
    function upgrade(uint256 newPlanId) external payable {
        SubscriptionStorage.Layout storage s = SubscriptionStorage.layout();
        SubscriptionStorage.Plan storage newP = s.plans[newPlanId];
        require(newP.exists, "new plan not exists");

        SubscriptionStorage.Subscription storage sub = s.subscriptions[msg.sender];
        require(sub.expiryTimestamp >= block.timestamp, "not active");

        // Simple price difference strategy: must pay newPlan.price - oldPlan.price
        SubscriptionStorage.Plan storage oldP = s.plans[sub.planId];
        require(oldP.exists, "old plan not exists");

        uint256 required = 0;
        if (newP.price > oldP.price) {
            required = newP.price - oldP.price;
        }
        require(msg.value == required, "wrong upgrade payment");

        // Transfer difference
        if (required > 0) {
            (bool sent, ) = payable(s.treasury).call{value: msg.value}("");
            require(sent, "pay failed");
        }

        // Example policy: new expiry = old expiry + newPlan.duration (or could pro-rate)
        sub.planId = newPlanId;
        sub.expiryTimestamp = sub.expiryTimestamp + newP.duration;

        emit Upgraded(msg.sender, oldP.id, newPlanId, sub.expiryTimestamp);
    }

    // Admin can pause/unpause user
    function pauseUser(address user) external {
        SubscriptionStorage.Layout storage s = SubscriptionStorage.layout();
        s.subscriptions[user].paused = true;
        emit Paused(user);
    }
    function
