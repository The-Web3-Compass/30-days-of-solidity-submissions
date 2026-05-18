// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SubscriptionStorageLayout.sol";

/// @title SubscriptionLogicV2
/// @notice Upgraded implementation that adds account pause / resume capability.
///         Swap the proxy's logicContract to this address to activate V2 features.
///
///         STORAGE SAFETY RULES
///         ─────────────────────
///         • This contract inherits SubscriptionStorageLayout — the SAME layout
///           as V1.  Slot order is identical.
///         • Do NOT declare new state variables here or in the layout above any
///           existing variable.  New variables must always be appended at the
///           BOTTOM of SubscriptionStorageLayout.  Inserting earlier will shift
///           slot assignments and corrupt logicContract / owner / all mappings.
///
/// @dev    Like V1, no state lives in this contract — every storage operation
///         targets the proxy's storage via delegatecall.
contract SubscriptionLogicV2 is SubscriptionStorageLayout {

    // ─── Events ────────────────────────────────────────────────────────────────
    event PlanAdded(string indexed plan, uint256 price, uint256 duration);
    event Subscribed(address indexed user, string plan, uint256 endTime);
    event AccountPaused(address indexed user);
    event AccountResumed(address indexed user);

    // ─── Modifiers ────────────────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Logic: not owner");
        _;
    }

    // ─── Admin — plan management (unchanged from V1) ───────────────────────────
    /// @notice Register or update a subscription plan.
    /// @param plan     Human-readable plan identifier (e.g. "monthly", "annual").
    /// @param price    Cost in wei to subscribe to this plan.
    /// @param duration Length of the subscription in seconds.
    function addPlan(
        string calldata plan,
        uint256 price,
        uint256 duration
    ) external onlyOwner {
        require(bytes(plan).length > 0, "LogicV2: empty plan name");
        require(price    > 0,           "LogicV2: price must be > 0");
        require(duration > 0,           "LogicV2: duration must be > 0");

        planPrices[plan]   = price;
        planDuration[plan] = duration;

        emit PlanAdded(plan, price, duration);
    }

    // ─── Subscription (unchanged from V1) ─────────────────────────────────────
    /// @notice Subscribe (or renew) a sender's account to a plan.
    ///         Must send exactly the plan price in ETH.
    /// @param plan The plan identifier to subscribe to.
    function subscribe(string calldata plan) external payable {
        uint256 price    = planPrices[plan];
        uint256 duration = planDuration[plan];

        require(price    > 0,             "LogicV2: plan does not exist");
        require(msg.value == price,       "LogicV2: incorrect ETH amount");

        require(!subscriptions[msg.sender].paused, "LogicV2: account is paused");

                uint256 start = block.timestamp;
                uint256 end   = start + duration;

                subscriptions[msg.sender] = Subscription({
                    startTime: start,
                    endTime:   end,
                    plan:      plan,
                    paused:    false
                });

        emit Subscribed(msg.sender, plan, end);
    }

    // ─── Views (unchanged from V1) ─────────────────────────────────────────────
    /// @notice Returns true if the user has an active, non-paused subscription.
    /// @param user The address to check.
    function isActive(address user) external view returns (bool) {
        Subscription storage sub = subscriptions[user];
        return sub.endTime > 0 && block.timestamp < sub.endTime && !sub.paused;
    }

    // ─── V2: Pause / Resume ────────────────────────────────────────────────────
    /// @notice Pause a subscriber's account so `isActive` returns false.
    ///         Only the owner can pause an account (e.g. for ToS violations).
    /// @param user The subscriber address to pause.
    function pauseAccount(address user) external onlyOwner {
        require(subscriptions[user].endTime > 0, "LogicV2: no subscription found");
        require(!subscriptions[user].paused,      "LogicV2: account already paused");

        subscriptions[user].paused = true;
        emit AccountPaused(user);
    }

    /// @notice Resume a previously paused account.
    ///         Paused time is NOT credited back — the original endTime stands.
    /// @param user The subscriber address to resume.
    function resumeAccount(address user) external onlyOwner {
        require(subscriptions[user].endTime > 0, "LogicV2: no subscription found");
        require(subscriptions[user].paused,       "LogicV2: account is not paused");

        subscriptions[user].paused = false;
        emit AccountResumed(user);
    }
}
