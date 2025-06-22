  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

// you can store a secret, but you can’t retrieve it until a specific time has passed.
contract TimeLockedDepositBox is BaseDepositBox {
    // 增加一个时间限制
    uint256 private unlockTime;

    // 写入一个duration，当到达这些时间之后才能操作
    constructor(uint256 lockDuration) {
        unlockTime = block.timestamp + lockDuration;
    }
    // 当前时间如果还没到时间会报错
    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still time-locked");
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

    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }
}

