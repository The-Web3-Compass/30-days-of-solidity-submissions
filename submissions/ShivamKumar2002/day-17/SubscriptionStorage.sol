// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SubscriptionStorage
 * @author shivam
 * @notice Defines the storage layout, structs, events, and errors for the upgradeable subscription manager.
 * @dev This contract is inherited by both the Proxy and Logic contracts to ensure consistent storage access.
 * @dev IMPORTANT: The order and types of variables declared here MUST NOT be changed in incompatible ways across upgrades if the logic contracts directly access storage slots.
 * New variables MUST be appended at the end.
 */
abstract contract SubscriptionStorage {
    /**
     * @notice Struct to store details of a subscription plan.
     * @param name Name of the plan (e.g., "Basic", "Pro").
     * @param duration Subscription duration in seconds.
     * @param exists Flag to check if planId maps to a valid plan.
     */
    struct Plan {
        string name;
        uint256 duration;
        bool exists;
    }


    /**
     * @notice Struct to store a user's subscription information.
     * @param planId The ID of the plan the user is subscribed to.
     * @param expiryTimestamp The Unix timestamp when the subscription expires.
     */
    struct SubscriptionInfo {
        uint256 planId;
        uint256 expiryTimestamp;
        // V2 Storage: New variables MUST be added below existing ones.
        uint256 pauseStartTime; // 0 if not paused, otherwise timestamp when pause began
    }

    /**
     * @notice Storage slot for owner address.
     * @dev Uses keccak256 of a unique string to ensure a low chance of collision.
     * IMPORTANT: This slot MUST remain the same across all versions of logic contract and proxy.
     * Following a convention similar to EIP-1967 (admin slot is keccak256("eip1967.proxy.admin") - 1).
     */
    bytes32 private constant OWNER_STORAGE_SLOT = bytes32(uint256(keccak256("com.shivam.subscription.proxy.owner")) - 1);

    // --- Storage Variables ---
    // NOTE: The proxy contract will reserve initial slots for its own upgrade mechanism variables.
    // Logic contracts will access the following variables assuming they start after the proxy's reserved slots.

    /// @notice Mapping from plan ID to plan details.
    mapping(uint256 => Plan) internal plans;
    /// @notice Counter to generate unique plan IDs. Starts at 1.
    uint256 internal nextPlanId;
    /// @notice Mapping from user address to their subscription details.
    mapping(address => SubscriptionInfo) internal userSubscriptions;

    // --- Internal Owner Storage Access ---
    /**
     * @dev Internal function to read the owner address from the specific storage slot.
     * Uses assembly (`sload`) for direct slot access.
     */
    function _getOwner() internal view returns (address ownerAddress) {
        bytes32 slot = OWNER_STORAGE_SLOT;
        // Addresses are 20 bytes (160 bits). They are stored right-aligned in a 32-byte (256-bit) slot.
        // sload reads the full 32 bytes, and the assignment to an address variable truncates appropriately.
        assembly {
            ownerAddress := sload(slot)
        }
    }

    /**
     * @dev Internal function to write the owner address to the specific storage slot.
     * Uses assembly (`sstore`) for direct slot access.
     */
    function _setOwner(address newOwnerAddress) internal {
        bytes32 slot = OWNER_STORAGE_SLOT;
        // sstore writes the full 32 bytes. Solidity handles casting address to bytes32 correctly (padding with zeros).
        assembly {
            sstore(slot, newOwnerAddress)
        }
    }

    /// @notice Error thrown when an action is attempted by an address other than the owner.
    error NotOwner();
    /// @notice Error thrown when trying to access or use a plan ID that does not exist.
    error PlanNotFound();
    /// @notice Error thrown when trying to subscribe while already having an active subscription.
    error AlreadySubscribed();
    /// @notice Error thrown when trying to perform an action that requires an active subscription (e.g., upgrade) but the user is not subscribed.
    error NotSubscribed();
    /// @notice Error thrown when trying to perform an action on an expired subscription that requires it to be active.
    error SubscriptionExpired();
    /// @notice Error thrown when trying to pause an already paused subscription (V2).
    error AlreadyPaused();
    /// @notice Error thrown when trying to resume a subscription that is not paused (V2).
    error NotPaused();
}