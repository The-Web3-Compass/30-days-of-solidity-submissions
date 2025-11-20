// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SubscriptionLogicV1 {
    // Event
    event PlanSubscribed(address indexed user, uint256 planId, uint256 expiry);

    // --- Storage layout ---
    // Must match the proxy storage exactly
    struct StorageLayout {
        mapping(address => uint256) userPlans;
        mapping(address => uint256) expiryDates;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("upgradehub.proxy.storage.layout");

    function _getStorage() internal pure returns (StorageLayout storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    // --- Core logic ---
    function subscribe(uint256 planId, uint256 durationDays) external {
        require(planId > 0, "Invalid plan");
        StorageLayout storage s = _getStorage();

        s.userPlans[msg.sender] = planId;
        s.expiryDates[msg.sender] = block.timestamp + (durationDays * 1 days);

        emit PlanSubscribed(msg.sender, planId, s.expiryDates[msg.sender]);
    }

    function getSubscription(address user)
        external
        view
        returns (uint256 planId, uint256 expiry)
    {
        StorageLayout storage s = _getStorage();
        return (s.userPlans[user], s.expiryDates[user]);
    }
}
