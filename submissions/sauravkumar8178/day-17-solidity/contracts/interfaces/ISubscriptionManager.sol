// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISubscriptionManager {
    // admin
    function initialize(address _owner) external;
    function addPlan(uint256 priceWei, uint32 durationDays) external returns (uint256);
    function setPlanActive(uint256 planId, bool active) external;

    // user
    function subscribe(uint256 planId) external payable;
    function renew() external payable;
    function cancelSubscription() external;
    function isActive(address user) external view returns (bool);
    function getSubscription(address user) external view returns (uint256 planId, uint64 expiry, bool paused);

    // owner
    function pauseAccount(address user) external;
    function resumeAccount(address user) external;
    function withdraw(address payable to) external;
}
