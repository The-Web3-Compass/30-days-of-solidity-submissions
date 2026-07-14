// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    // 新增状态变量：解锁时间（区块时间戳）
    uint256 private unlockTime;

    // 构造函数：接收“锁定时长（秒）”，计算解锁时间
    constructor(uint256 lockDuration) {
        unlockTime = block.timestamp + lockDuration; // 部署时间 + 锁定时长 = 解锁时间
    }

    // 新增修饰符：限制仅解锁后可调用函数
    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still time-locked");
        _;
    }

    // 实现接口的getBoxType()：标识为“TimeLocked”类型
    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }

    // 重写getSecret()：增加时间锁定检查（仅所有者+解锁后可读取）
    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
        return super.getSecret(); // 调用父合约的getSecret()逻辑
    }

    // 新增功能：获取解锁时间（供前端显示）
    function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }

    // 新增功能：获取剩余锁定时间（秒），解锁后返回0
    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }
}