// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseDepositBox} from "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    error TimeLockedDepositBox_TimeLocked();

    uint256 private unlockTime;

    modifier timeUnlocked() {
        if ((block.timestamp > unlockTime)) revert TimeLockedDepositBox_TimeLocked();
        _;
    }

    constructor(uint256 lockDuration) {
        unlockTime = block.timestamp + lockDuration;
    }

    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }

    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
        return super.getSecret();
    }

    function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }

    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }

}