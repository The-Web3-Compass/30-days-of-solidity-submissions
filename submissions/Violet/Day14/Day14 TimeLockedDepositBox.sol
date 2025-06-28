// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day14 BaseDepositBox.sol";


contract TimeLockedDepositBox is BaseDepositBox {

    uint256 public unlockTime;

    modifier checkLock() {
        require(block.timestamp >= unlockTime, "Box is still time-locked");
        _;
    }

    constructor(address initialOwner, uint256 lockDurationSeconds) BaseDepositBox(initialOwner) {
        require(lockDurationSeconds > 0, "Lock duration must be positive");
        unlockTime = block.timestamp + lockDurationSeconds;
    }

    /**
     * @dev 重写 retrieve 函数，增加时间锁检查。
     */
    function retrieve() public view override onlyOwner checkLock returns (string memory) {
        return super.retrieve(); // 调用父合约的基础 retrieve 逻辑
    }
}
