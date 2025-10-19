// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AdminOnly {
    // State variables
    address public owner;
    uint256 public treasureAmount;
    uint256 public maxWithdrawalLimit;
    uint256 public withdrawalCooldown;
    
    // Mappings
    mapping(address => uint256) public withdrawAllowance;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint256) public lastWithdrawalTime;
    
    // Events 
    event TreasureAdded(address indexed by, uint256 amount, uint256 newBalance);
    event WithdrawalApproved(address indexed recipient, uint256 amount);
    event TreasureWithdrawn(address indexed by, uint256 amount, uint256 remainingBalance);
    event WithdrawalStatusReset(address indexed user);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MaxWithdrawalLimitChanged(uint256 oldLimit, uint256 newLimit);
    event CooldownPeriodChanged(uint256 oldPeriod, uint256 newPeriod);
    
    // Custom errors
    error AccessDenied();
    error InsufficientBalance();
    error NoWithdrawalAllowance();
    error AlreadyWithdrawn();
    error WithdrawalLimitExceeded();
    error CooldownPeriodActive();
    error InvalidAddress();
    error InvalidAmount();

    constructor(uint256 _maxWithdrawalLimit, uint256 _withdrawalCooldown) {
        owner = msg.sender;
        maxWithdrawalLimit = _maxWithdrawalLimit;
        withdrawalCooldown = _withdrawalCooldown;
        
        emit OwnershipTransferred(address(0), msg.sender);
        emit MaxWithdrawalLimitChanged(0, _maxWithdrawalLimit);
        emit CooldownPeriodChanged(0, _withdrawalCooldown);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert AccessDenied();
        _;
    }

    function addTreasure(uint256 amount) external onlyOwner {
        if (amount == 0) revert InvalidAmount();
        
        treasureAmount += amount;
        emit TreasureAdded(msg.sender, amount, treasureAmount);
    }

    function approvedWithdrawal(address recipient, uint256 amount) external onlyOwner {
        if (recipient == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();
        if (amount > treasureAmount) revert InsufficientBalance();
        if (amount > maxWithdrawalLimit) revert WithdrawalLimitExceeded();
        
        withdrawAllowance[recipient] = amount;
        emit WithdrawalApproved(recipient, amount);
    }

    function withdrawTreasure(uint256 amount) external {
        // Owner withdrawal path
        if (msg.sender == owner) {
            if (amount > treasureAmount) revert InsufficientBalance();
            treasureAmount -= amount;
            emit TreasureWithdrawn(msg.sender, amount, treasureAmount);
            
            // Transfer actual ETH to the owner
            (bool success, ) = payable(owner).call{value: amount}("");
            require(success, "Transfer failed");
            return;
        }

        // Regular user withdrawal path
        uint256 allowance = withdrawAllowance[msg.sender];
        if (allowance == 0) revert NoWithdrawalAllowance();
        if (hasWithdrawn[msg.sender]) revert AlreadyWithdrawn();
        if (allowance > treasureAmount) revert InsufficientBalance();
        if (amount > allowance) revert WithdrawalLimitExceeded();
        
        // Check cooldown period
        if (block.timestamp < lastWithdrawalTime[msg.sender] + withdrawalCooldown && 
            lastWithdrawalTime[msg.sender] != 0) {
            revert CooldownPeriodActive();
        }

        hasWithdrawn[msg.sender] = true;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        treasureAmount -= amount;
        withdrawAllowance[msg.sender] = 0;
        
        emit TreasureWithdrawn(msg.sender, amount, treasureAmount);
        
        // Transfer actual ETH to the user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function resetWithdrawalStatus(address user) external onlyOwner {
        if (user == address(0)) revert InvalidAddress();
        
        hasWithdrawn[user] = false;
        emit WithdrawalStatusReset(user);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setMaxWithdrawalLimit(uint256 newLimit) external onlyOwner {
        uint256 oldLimit = maxWithdrawalLimit;
        maxWithdrawalLimit = newLimit;
        emit MaxWithdrawalLimitChanged(oldLimit, newLimit);
    }

    function setWithdrawalCooldown(uint256 newCooldown) external onlyOwner {
        uint256 oldCooldown = withdrawalCooldown;
        withdrawalCooldown = newCooldown;
        emit CooldownPeriodChanged(oldCooldown, newCooldown);
    }

    function getTreasureDetails() external view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    function getUserStatus(address user) external view returns (
        bool isApproved,
        uint256 allowanceAmount,
        bool hasAlreadyWithdrawn,
        uint256 cooldownRemaining
    ) {
        isApproved = withdrawAllowance[user] > 0;
        allowanceAmount = withdrawAllowance[user];
        hasAlreadyWithdrawn = hasWithdrawn[user];
        
        uint256 lastWithdrawal = lastWithdrawalTime[user];
        if (lastWithdrawal == 0 || block.timestamp >= lastWithdrawal + withdrawalCooldown) {
            cooldownRemaining = 0;
        } else {
            cooldownRemaining = lastWithdrawal + withdrawalCooldown - block.timestamp;
        }
    }
    
    receive() external payable {
        treasureAmount += msg.value;
        emit TreasureAdded(msg.sender, msg.value, treasureAmount);
    }
}