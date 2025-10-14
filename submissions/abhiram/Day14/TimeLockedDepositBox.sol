//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./BaseDepositBox.sol";

/**
 * @title TimeLockedDepositBox
 * @notice A time-locked deposit box where funds cannot be withdrawn until a specified time
 * @dev Adds lock period functionality to restrict withdrawals
 */
contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public immutable lockDuration;
    uint256 public lockEndTime;
    
    /**
     * @notice Create a new time-locked deposit box
     * @param initialOwner Address of the initial owner
     * @param _lockDuration Duration in seconds for which funds are locked
     */
    constructor(address initialOwner, uint256 _lockDuration) BaseDepositBox(initialOwner) {
        require(_lockDuration > 0, "Lock duration must be greater than 0");
        lockDuration = _lockDuration;
        lockEndTime = block.timestamp + _lockDuration;
    }
    
    /**
     * @inheritdoc IDepositBox
     * @dev Overrides to add time-lock check
     */
    function withdraw(uint256 amount) external override onlyOwner {
        require(block.timestamp >= lockEndTime, "Funds are still locked");
        _withdraw(amount);
    }
    
    /**
     * @notice Extend the lock period
     * @param additionalTime Additional time in seconds to extend the lock
     */
    function extendLock(uint256 additionalTime) external onlyOwner {
        require(additionalTime > 0, "Additional time must be greater than 0");
        lockEndTime += additionalTime;
    }
    
    /**
     * @notice Get the remaining lock time
     * @return Remaining time in seconds, or 0 if unlocked
     */
    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= lockEndTime) {
            return 0;
        }
        return lockEndTime - block.timestamp;
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }
}
