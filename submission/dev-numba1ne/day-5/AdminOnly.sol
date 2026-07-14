// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    // State variables
    address public owner;
    uint256 public treasureAmount;
    uint256 public maxWithdrawalLimit;
    uint256 public cooldownPeriod; // Cooldown period in seconds
    
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint256) public lastWithdrawalTime;
    
    // Events
    event TreasureAdded(address indexed by, uint256 amount, uint256 newTotal);
    event WithdrawalApproved(address indexed owner, address indexed recipient, uint256 amount);
    event TreasureWithdrawn(address indexed by, uint256 amount, uint256 remaining);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrawalStatusReset(address indexed user);
    event MaxWithdrawalLimitSet(uint256 newLimit);
    event CooldownPeriodSet(uint256 newPeriod);
    
    // Constructor sets the contract creator as the owner
    constructor(uint256 _cooldownPeriod, uint256 _maxWithdrawalLimit) {
        owner = msg.sender;
        cooldownPeriod = _cooldownPeriod;
        maxWithdrawalLimit = _maxWithdrawalLimit;
        emit OwnershipTransferred(address(0), msg.sender);
        emit CooldownPeriodSet(_cooldownPeriod);
        emit MaxWithdrawalLimitSet(_maxWithdrawalLimit);
    }
    
    // Modifier for owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }
    
    // Modifier to check if cooldown period has passed
    modifier cooldownPassed() {
        require(
            block.timestamp >= lastWithdrawalTime[msg.sender] + cooldownPeriod || 
            lastWithdrawalTime[msg.sender] == 0,
            "Cooldown period has not passed yet"
        );
        _;
    }
    
    // Only the owner can add treasure
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
        emit TreasureAdded(msg.sender, amount, treasureAmount);
    }
    
    // Only the owner can approve withdrawals
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        require(amount <= maxWithdrawalLimit, "Amount exceeds maximum withdrawal limit");
        withdrawalAllowance[recipient] = amount;
        emit WithdrawalApproved(msg.sender, recipient, amount);
    }
    
    // Anyone can attempt to withdraw, but only those with allowance will succeed
    function withdrawTreasure(uint256 amount) public cooldownPassed {
        if(msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount -= amount;
            emit TreasureWithdrawn(msg.sender, amount, treasureAmount);
            return;
        }
        
        uint256 allowance = withdrawalAllowance[msg.sender];
        
        // Check if user has an allowance and hasn't withdrawn yet
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed");
        
        // Mark as withdrawn, update last withdrawal time, and reduce treasure
        hasWithdrawn[msg.sender] = true;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] -= amount;
        
        emit TreasureWithdrawn(msg.sender, amount, treasureAmount);
    }
    
    // Only the owner can reset someone's withdrawal status
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
        emit WithdrawalStatusReset(user);
    }
    
    // Only the owner can transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    // Only the owner can set a new cooldown period
    function setCooldownPeriod(uint256 _cooldownPeriod) public onlyOwner {
        cooldownPeriod = _cooldownPeriod;
        emit CooldownPeriodSet(_cooldownPeriod);
    }
    
    // Only the owner can set a new maximum withdrawal limit
    function setMaxWithdrawalLimit(uint256 _maxWithdrawalLimit) public onlyOwner {
        maxWithdrawalLimit = _maxWithdrawalLimit;
        emit MaxWithdrawalLimitSet(_maxWithdrawalLimit);
    }
    
    // View function to get treasure details
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
    
    // View function for users to check their withdrawal status
    function getUserWithdrawalStatus(address user) public view returns (
        uint256 allowance,
        bool withdrawn,
        uint256 timeUntilNextWithdrawal,
        bool canWithdrawNow
    ) {
        allowance = withdrawalAllowance[user];
        withdrawn = hasWithdrawn[user];
        
        uint256 timeSinceLastWithdrawal = block.timestamp - lastWithdrawalTime[user];
        if (lastWithdrawalTime[user] == 0 || timeSinceLastWithdrawal >= cooldownPeriod) {
            timeUntilNextWithdrawal = 0;
            canWithdrawNow = !withdrawn && allowance > 0;
        } else {
            timeUntilNextWithdrawal = cooldownPeriod - timeSinceLastWithdrawal;
            canWithdrawNow = false;
        }
    }
}
