// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint256) public maxWithdrawalLimit; // 设置每个用户的最大提取上限
    uint256 public cooldownPeriod = 1 hours;  // 冷却时间：1小时

    // 事件
    event TreasureAdded(address indexed by, uint256 amount);
    event WithdrawalApproved(address indexed recipient, uint256 amount);
    event TreasureWithdrawn(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // Constructor sets the contract creator as the owner
    constructor() {
        owner = msg.sender;
    }
    
    // Modifier for owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }
    
    // Only the owner can add treasure
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
        emit TreasureAdded(msg.sender, amount);
    }
    
    // Only the owner can approve withdrawals
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
        emit WithdrawalApproved(recipient, amount);
    }
    
    // Set the max withdrawal limit for each user
    function setMaxWithdrawalLimit(address recipient, uint256 limit) public onlyOwner {
        maxWithdrawalLimit[recipient] = limit;
    }

    // Anyone can attempt to withdraw, but only those with allowance will succeed
    function withdrawTreasure(uint256 amount) public {
        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount -= amount;
            emit TreasureWithdrawn(msg.sender, amount);
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];
        
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed");
        
        // Check for cooldown period
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + cooldownPeriod, "Cooldown period has not passed yet.");
        
        // Ensure the withdrawal does not exceed the max withdrawal limit
        require(amount <= maxWithdrawalLimit[msg.sender], "Amount exceeds the maximum withdrawal limit");

        // Mark as withdrawn, update time and reduce treasure
        hasWithdrawn[msg.sender] = true;
        lastWithdrawalTime[msg.sender] = block.timestamp; // Update withdrawal time
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] = 0;
        
        emit TreasureWithdrawn(msg.sender, amount);
    }
    
    // Only the owner can reset someone's withdrawal status
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // Only the owner can transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Get treasure details (only for the owner)
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    // Query functions for users
    function getUserAllowance(address user) public view returns (uint256) {
        return withdrawalAllowance[user];
    }

    function hasUserWithdrawn(address user) public view returns (bool) {
        return hasWithdrawn[user];
    }

    function getMaxWithdrawalLimit(address user) public view returns (uint256) {
        return maxWithdrawalLimit[user];
    }

    function getCooldownTimeRemaining(address user) public view returns (uint256) {
        if (block.timestamp >= lastWithdrawalTime[user] + cooldownPeriod) {
            return 0;  // No cooldown left
        }
        return (lastWithdrawalTime[user] + cooldownPeriod) - block.timestamp;
    }
}
