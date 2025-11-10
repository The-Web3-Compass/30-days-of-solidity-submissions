// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SubscriptionLogicV2 {
    event PlanSubscribed(address indexed user, uint256 planId, uint256 expiry);
    event SubscriptionPaused(address indexed user, bool status);

    // --- Storage layout ---
    struct StorageLayout {
        mapping(address => uint256) userPlans;
        mapping(address => uint256) expiryDates;
        mapping(address => bool) paused;
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
        StorageLayout storage s = _getStorage();
        require(!s.paused[msg.sender], "Subscription paused");
        require(planId > 0, "Invalid plan");

        s.userPlans[msg.sender] = planId;
        s.expiryDates[msg.sender] = block.timestamp + (durationDays * 1 days);

        emit PlanSubscribed(msg.sender, planId, s.expiryDates[msg.sender]);
    }

    function pauseSubscription(bool _status) external {
        StorageLayout storage s = _getStorage();
        s.paused[msg.sender] = _status;
        emit SubscriptionPaused(msg.sender, _status);
    }

    function getSubscription(address user)
        external
        view
        returns (uint256 planId, uint256 expiry, bool isPaused)
    {
        StorageLayout storage s = _getStorage();
        return (s.userPlans[user], s.expiryDates[user], s.paused[user]);
    }
}
