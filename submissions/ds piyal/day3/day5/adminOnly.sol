// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract adminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawAllowance;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public maxWithdrawalLimit;
    uint256 public cooldownPeriod = 300;
    
    event TreasureAdded(uint256 amount, uint256 newTotal);
    event TreasureWithdrawn(address indexed withdrawer, uint256 amount, uint256 remaining);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrawalApproved(address indexed recipient, uint256 amount, uint256 maxLimit);
    event CooldownPeriodUpdated(uint256 newCooldownPeriod);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access Denied:Only owner can action");
        _;
    }

    modifier cooldownCheck() {
        if (msg.sender != owner) {
            require(block.timestamp >= lastWithdrawalTime[msg.sender] + cooldownPeriod, 
                    "Cooldown period not finished. Please wait before withdrawing again");
        }
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
        emit TreasureAdded(amount, treasureAmount);
    }

    function approvedWithdrawal(address recipient, uint256 amount)
        public
        onlyOwner
    {
        require(amount <= treasureAmount, "Not enough available");
        withdrawAllowance[recipient] = amount;
        emit WithdrawalApproved(recipient, amount, maxWithdrawalLimit[recipient]);
    }

    function setMaxWithdrawalLimit(address user, uint256 maxLimit) public onlyOwner {
        require(user != address(0), "Invalid address");
        maxWithdrawalLimit[user] = maxLimit;
    }

    function setCooldownPeriod(uint256 newCooldownPeriod) public onlyOwner {
        cooldownPeriod = newCooldownPeriod;
        emit CooldownPeriodUpdated(newCooldownPeriod);
    }

    function withdrawTreasure(uint256 amount) public cooldownCheck {
        if (msg.sender == owner) {
            require(treasureAmount >= amount, "Insufficient Balance");
            treasureAmount -= amount;
            emit TreasureWithdrawn(msg.sender, amount, treasureAmount);
            return;
        }

        uint256 allowance = withdrawAllowance[msg.sender];
        require(allowance > 0, "Access Denied:No withdrawal allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrew.");
        require(allowance <= treasureAmount, "Not enough balance to withdraw");
        require(allowance >= amount,"Cannot withdraw more than you are allowed");
        
        if (maxWithdrawalLimit[msg.sender] > 0) {
            require(amount <= maxWithdrawalLimit[msg.sender], "Amount exceeds maximum withdrawal limit");
        }

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawAllowance[msg.sender] = 0;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        
        emit TreasureWithdrawn(msg.sender, amount, treasureAmount);
    }

    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    function checkUserStatus(address user) public view returns (
        bool isApproved,
        bool hasAlreadyWithdrawn,
        uint256 approvedAmount,
        uint256 maxLimit,
        uint256 cooldownRemaining
    ) {
        isApproved = withdrawAllowance[user] > 0;
        hasAlreadyWithdrawn = hasWithdrawn[user];
        approvedAmount = withdrawAllowance[user];
        maxLimit = maxWithdrawalLimit[user];
        
        if (user == owner) {
            cooldownRemaining = 0;
        } else {
            uint256 timeSinceLastWithdrawal = block.timestamp - lastWithdrawalTime[user];
            if (timeSinceLastWithdrawal >= cooldownPeriod) {
                cooldownRemaining = 0;
            } else {
                cooldownRemaining = cooldownPeriod - timeSinceLastWithdrawal;
            }
        }
    }

    function getMyStatus() public view returns (
        bool isApproved,
        bool hasAlreadyWithdrawn,
        uint256 approvedAmount,
        uint256 maxLimit,
        uint256 cooldownRemaining
    ) {
        return checkUserStatus(msg.sender);
    }
}