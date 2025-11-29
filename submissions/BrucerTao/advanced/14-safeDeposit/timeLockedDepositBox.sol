// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./baseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 private unlockTime;

    constructor(uint256 lockDuration) {
        unlockTime = block.timestamp + lockDuration;
    }

    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "box is still time-locked");
        _;
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

    //倒计时助手
    function getRemainingLockTime() external view returns (uint256) {
        if(block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }

}