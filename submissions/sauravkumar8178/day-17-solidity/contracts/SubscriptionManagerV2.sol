// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SubscriptionManagerV1.sol";

/// @title SubscriptionManagerV2
/// @notice Adds discountedSubscribe and demonstrates compatible upgrade.
/// IMPORTANT: Do not change storage ordering from V1.
contract SubscriptionManagerV2 is SubscriptionManagerV1 {
    event DiscountSubscribed(address indexed user, uint256 indexed planId, uint64 expiryTimestamp, uint256 paid);

    /// @notice Owner can allow discounted subscription using direct call from user with discounted amount.
    function discountedSubscribe(uint256 planId, uint256 discountedWei) external payable nonReentrant {
        Plan memory p = plans[planId];
        require(p.id != 0 && p.active, "invalid-plan");
        require(msg.value == discountedWei, "wrong-amount");
        require(discountedWei <= p.priceWei, "invalid-discount");

        uint64 newExpiry = uint64(block.timestamp + uint256(p.durationDays) * 1 days);
        subscriptions[msg.sender] = Subscription({ planId: planId, expiryTimestamp: newExpiry, paused: false });
        emit DiscountSubscribed(msg.sender, planId, newExpiry, msg.value);
    }

    // If new storage vars are needed later, append them AFTER the existing vars or use additional __gap.
}
