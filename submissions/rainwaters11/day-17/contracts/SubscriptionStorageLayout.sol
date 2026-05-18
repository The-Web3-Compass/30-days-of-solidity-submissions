// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SubscriptionStorageLayout
/// @notice Defines the canonical storage layout shared by the proxy and all logic contracts.
///         WARNING: NEVER change the order of these variables. Adding new state must always
///         go at the END of this file. Inserting or reordering will corrupt the proxy's
///         storage and overwrite critical addresses like `logicContract`.
contract SubscriptionStorageLayout {
    // ─── Slot 0 ──────────────────────────────────────────────────────────────
    /// @notice Address of the currently active logic (implementation) contract.
    address public logicContract;

    // ─── Slot 1 ──────────────────────────────────────────────────────────────
    /// @notice Address of the contract owner, set once in the proxy constructor.
    address public owner;

    // ─── Subscription struct ─────────────────────────────────────────────────
    /// @notice Represents a single user's subscription record.
    /// @dev `paused` is included from v1 so that storage slots remain stable
    ///      when LogicV2 activates pause/resume functionality.
    struct Subscription {
        uint256 startTime;   // Timestamp when the subscription began
        uint256 endTime;     // Timestamp when the subscription expires
        string  plan;        // Name of the subscribed plan (e.g. "monthly")
        bool    paused;      // True if the account is paused (V2+)
    }

    // ─── Mappings ─────────────────────────────────────────────────────────────
    /// @notice Maps a subscriber address to their Subscription record.
    mapping(address => Subscription) public subscriptions;

    /// @notice Maps a plan name to its price in wei.
    mapping(string => uint256) public planPrices;

    /// @notice Maps a plan name to its duration in seconds.
    mapping(string => uint256) public planDuration;
}
