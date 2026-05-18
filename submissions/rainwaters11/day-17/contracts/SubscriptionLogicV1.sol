// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SubscriptionStorageLayout.sol";

/// @title SubscriptionLogicV1
/// @notice First implementation of subscription business logic.
///         Deployed separately and pointed to by the SubscriptionStorage proxy.
///         All state reads/writes operate on the PROXY's storage via delegatecall —
///         this contract itself stores nothing.
///
/// @dev    Inherits SubscriptionStorageLayout so that compiled slot references
///         align perfectly with the proxy's storage during delegatecall execution.
contract SubscriptionLogicV1 is SubscriptionStorageLayout {

    // ─── Events ────────────────────────────────────────────────────────────────
    event PlanAdded(string indexed plan, uint256 price, uint256 duration);
    event Subscribed(address indexed user, string plan, uint256 endTime);

    // ─── Modifiers ────────────────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Logic: not owner");
        _;
    }

    // ─── Admin ────────────────────────────────────────────────────────────────
    /// @notice Register or update a subscription plan.
    /// @param plan     Human-readable plan identifier (e.g. "monthly", "annual").
    /// @param price    Cost in wei to subscribe to this plan.
    /// @param duration Length of the subscription in seconds.
    function addPlan(
        string calldata plan,
        uint256 price,
        uint256 duration
    ) external onlyOwner {
        require(bytes(plan).length > 0, "LogicV1: empty plan name");
        require(price    > 0,           "LogicV1: price must be > 0");
        require(duration > 0,           "LogicV1: duration must be > 0");

        planPrices[plan]   = price;
        planDuration[plan] = duration;

        emit PlanAdded(plan, price, duration);
    }

    // ─── Subscription ─────────────────────────────────────────────────────────
    /// @notice Subscribe (or renew) a sender's account to a plan.
    ///         Must send exactly the plan price in ETH.
    /// @param plan The plan identifier to subscribe to.
    function subscribe(string calldata plan) external payable {
        uint256 price    = planPrices[plan];
        uint256 duration = planDuration[plan];

        require(price    > 0, "LogicV1: plan does not exist");
        require(msg.value == price, "LogicV1: incorrect ETH amount");

        Subscription storage current = subscriptions[msg.sender];
        uint256 start = current.endTime > block.timestamp ? current.endTime : block.timestamp;
        uint256 end   = start + duration;

        subscriptions[msg.sender] = Subscription({
            startTime: start,
            endTime:   end,
            plan:      plan,
            paused:    false
        });

        emit Subscribed(msg.sender, plan, end);
    }

    // ─── Views ────────────────────────────────────────────────────────────────
    /// @notice Returns true if the caller's subscription exists and has not expired.
    /// @param user The address to check.
    function isActive(address user) external view returns (bool) {
        Subscription storage sub = subscriptions[user];
        return sub.endTime > 0 && block.timestamp < sub.endTime && !sub.paused;
    }

    function withdrawRevenue() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "LogicV1: no ETH to withdraw");

        (bool sent, ) = payable(owner).call{value: amount}("");
        require(sent, "LogicV1: ETH transfer failed");
    }
    }
