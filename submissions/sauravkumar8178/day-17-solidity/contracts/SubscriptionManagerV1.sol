// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ISubscriptionManager.sol";

/// @title SubscriptionManagerV1
/// @notice Logic contract for subscription management. Designed to be called through UpgradeableProxy via delegatecall.
/// Storage layout must remain compatible across upgrades. Use __gap to allow future expansion.
contract SubscriptionManagerV1 is ISubscriptionManager {
    // -------- STORAGE (preserve order across upgrades) --------
    address public owner;           // slot 0
    uint256 public nextPlanId;      // slot 1

    struct Plan {
        uint256 id;
        uint256 priceWei;
        uint32 durationDays;
        bool active;
    }

    mapping(uint256 => Plan) public plans;              // slot 2 (mapping)
    struct Subscription {
        uint256 planId;
        uint64 expiryTimestamp;
        bool paused;
    }
    mapping(address => Subscription) public subscriptions; // slot 3 (mapping)

    // Reentrancy guard (included in initial layout)
    uint8 private _locked; // 0 = unlocked, 1 = locked

    // events
    event PlanAdded(uint256 indexed planId, uint256 priceWei, uint32 durationDays);
    event PlanUpdated(uint256 indexed planId, bool active);
    event Subscribed(address indexed user, uint256 indexed planId, uint64 expiryTimestamp);
    event Renewed(address indexed user, uint256 indexed planId, uint64 newExpiry);
    event Cancelled(address indexed user);
    event Paused(address indexed user);
    event Resumed(address indexed user);
    event Withdrawn(address indexed to, uint256 amount);

    // gap for future storage
    uint256[46] private __gap; // adjusted to keep total gap approx 50 slots (including _locked)

    // -------- modifiers --------
    modifier onlyOwner() {
        require(msg.sender == owner, "not-owner");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 0, "reentrant");
        _locked = 1;
        _;
        _locked = 0;
    }

    // -------- initializer (no constructor, called via proxy) --------
    function initialize(address _owner) external override {
        require(owner == address(0), "already-initialized");
        require(_owner != address(0), "owner=0");
        owner = _owner;
        nextPlanId = 1;
        _locked = 0;
    }

    // -------- admin functions --------
    function addPlan(uint256 priceWei, uint32 durationDays) external override onlyOwner returns (uint256) {
        require(durationDays > 0, "duration=0");
        uint256 pid = nextPlanId++;
        plans[pid] = Plan({ id: pid, priceWei: priceWei, durationDays: durationDays, active: true });
        emit PlanAdded(pid, priceWei, durationDays);
        return pid;
    }

    function setPlanActive(uint256 planId, bool active) external override onlyOwner {
        require(plans[planId].id != 0, "plan-not-found");
        plans[planId].active = active;
        emit PlanUpdated(planId, active);
    }

    // -------- user functions --------
    /// @notice subscribe by sending exact ETH matching plan price
    function subscribe(uint256 planId) external payable override nonReentrant {
        Plan memory p = plans[planId];
        require(p.id != 0 && p.active, "invalid-plan");
        require(msg.value == p.priceWei, "wrong-amount");

        uint64 newExpiry = uint64(block.timestamp + uint256(p.durationDays) * 1 days);
        subscriptions[msg.sender] = Subscription({ planId: planId, expiryTimestamp: newExpiry, paused: false });
        emit Subscribed(msg.sender, planId, newExpiry);
    }

    /// @notice renew existing subscription
    function renew() external payable override nonReentrant {
        Subscription storage s = subscriptions[msg.sender];
        require(s.planId != 0, "no-subscription");
        Plan memory p = plans[s.planId];
        require(p.active, "plan-inactive");
        require(msg.value == p.priceWei, "wrong-amount");

        uint64 base = s.expiryTimestamp > block.timestamp ? s.expiryTimestamp : uint64(block.timestamp);
        uint64 newExpiry = base + uint64(p.durationDays) * 1 days;
        s.expiryTimestamp = newExpiry;
        s.paused = false;
        emit Renewed(msg.sender, s.planId, newExpiry);
    }

    function cancelSubscription() external override {
        delete subscriptions[msg.sender];
        emit Cancelled(msg.sender);
    }

    function pauseAccount(address user) external override onlyOwner {
        subscriptions[user].paused = true;
        emit Paused(user);
    }

    function resumeAccount(address user) external override onlyOwner {
        subscriptions[user].paused = false;
        emit Resumed(user);
    }

    // -------- views --------
    function isActive(address user) public view override returns (bool) {
        Subscription memory s = subscriptions[user];
        if (s.planId == 0) return false;
        if (s.paused) return false;
        return uint256(s.expiryTimestamp) > block.timestamp;
    }

    function getSubscription(address user) external view override returns (uint256 planId, uint64 expiry, bool paused) {
        Subscription memory s = subscriptions[user];
        return (s.planId, s.expiryTimestamp, s.paused);
    }

    // -------- owner utils --------
    function withdraw(address payable to) external override onlyOwner nonReentrant {
        require(to != address(0), "to=0");
        uint256 bal = address(this).balance;
        require(bal > 0, "no-balance");
        // pull pattern: send funds after checks
        (bool ok, ) = to.call{value: bal}("");
        require(ok, "withdraw-failed");
        emit Withdrawn(to, bal);
    }
}
