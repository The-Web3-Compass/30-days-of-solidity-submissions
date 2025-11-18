// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

// TimeLockedDepositBox inherits from BaseDepositBox and adds a time lock feature
contract TimeLockedDepositBox is BaseDepositBox {

    // The timestamp when the box can be unlocked
    uint256 private unlockTime;

    // Constructor sets the unlock time based on the current time and lock duration
    constructor(uint256 lockDuration) {
        unlockTime = block.timestamp + lockDuration;
    }

    // Modifier that ensures the box is only accessible after the unlock time
    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still locked");
        _;
    }

    // Returns the type of the box as "TimeLocked"
    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }

    // Overrides getSecret to include time lock restriction
    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
        return super.getSecret();
    }

    // Returns the exact unlock time (timestamp)
    function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }

    // Returns how many seconds remain until the box is unlocked
    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }
}