//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./BaseDepositBox.sol";

/**
 * @title PremiumDepositBox
 * @notice A premium deposit box with enhanced security features
 * @dev Adds minimum balance requirement and daily withdrawal limits
 */
contract PremiumDepositBox is BaseDepositBox {
    uint256 public constant MINIMUM_BALANCE = 0.1 ether;
    uint256 public constant DAILY_WITHDRAWAL_LIMIT = 1 ether;
    
    uint256 private _lastWithdrawalDay;
    uint256 private _dailyWithdrawnAmount;
    
    /**
     * @notice Create a new premium deposit box
     * @param initialOwner Address of the initial owner
     */
    constructor(address initialOwner) BaseDepositBox(initialOwner) {}
    
    /**
     * @inheritdoc IDepositBox
     * @dev Overrides to add minimum balance check
     */
    function withdraw(uint256 amount) external override onlyOwner {
        uint256 currentBalance = this.getBalance();
        require(
            currentBalance - amount >= MINIMUM_BALANCE,
            "Cannot withdraw below minimum balance"
        );
        
        // Reset daily withdrawal counter if it's a new day
        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > _lastWithdrawalDay) {
            _lastWithdrawalDay = currentDay;
            _dailyWithdrawnAmount = 0;
        }
        
        require(
            _dailyWithdrawnAmount + amount <= DAILY_WITHDRAWAL_LIMIT,
            "Daily withdrawal limit exceeded"
        );
        
        _dailyWithdrawnAmount += amount;
        
        // Execute withdrawal using internal function
        _withdraw(amount);
    }
    
    /**
     * @notice Get remaining daily withdrawal allowance
     * @return Remaining amount that can be withdrawn today
     */
    function getRemainingDailyWithdrawal() external view returns (uint256) {
        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > _lastWithdrawalDay) {
            return DAILY_WITHDRAWAL_LIMIT;
        }
        return DAILY_WITHDRAWAL_LIMIT - _dailyWithdrawnAmount;
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }
}
