// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 private immutable _unlockTime;

    constructor(uint256 lockDuration) {
        require(lockDuration > 0, "Lock duration must be > 0");
        _unlockTime = block.timestamp + lockDuration;
    }

    modifier timeUnlocked() {
        require(block.timestamp >= _unlockTime, "Box still locked");
        _;
    }

    function getBoxType() public pure override returns (string memory) {
        return "TimeLocked";
    }

    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
        return super.getSecret();
    }

    function getUnlockTime() public view returns (uint256) {
        return _unlockTime;
    }

    function getRemainingLockTime() public view returns (uint256) {
        return block.timestamp >= _unlockTime ? 0 : _unlockTime - block.timestamp;
    }
}