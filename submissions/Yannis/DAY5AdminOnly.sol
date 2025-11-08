// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint256) public maxWithdrawalLimit;
    mapping(address => uint256) public withdrawnAmount;
    mapping(address => uint256) public lastWithdrawTime;
    uint256 public cooldownSeconds;

    function setUserMaxLimit(address user, uint256 maxAmount) public onlyOwner {
        maxWithdrawalLimit[user] = maxAmount;
        emit MaxLimitSet(user, maxAmount);
    }

    
    function setCooldownSeconds(uint256 seconds_) public onlyOwner {
        cooldownSeconds = seconds_;
        emit CooldownSet(seconds_);
    }

    function getUserStatus(address user) public view returns (
        uint256 allowance,
        bool hasEverWithdrawn,
        uint256 maxLimit,
        uint256 totalWithdrawn,
        uint256 lastWithdrawTimestamp
    ) {
        allowance = withdrawalAllowance[user];
        hasEverWithdrawn = hasWithdrawn[user];
        maxLimit = maxWithdrawalLimit[user];
        totalWithdrawn = withdrawnAmount[user];
        lastWithdrawTimestamp = lastWithdrawTime[user];
    }

    
    event TreasureAdded(uint256 amount);
    event WithdrawalApproved(address indexed recipient, uint256 amount);
    event TreasureWithdrawn(address indexed by, uint256 amount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event WithdrawalStatusReset(address indexed user);
    event MaxLimitSet(address indexed user, uint256 maxAmount);
    event CooldownSet(uint256 seconds_);
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }
    
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
        emit TreasureAdded(amount);
    }
    
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        if (maxWithdrawalLimit[recipient]>0){
            require(amount <= maxWithdrawalLimit[recipient], "Approved amount exceeds use's max limit");
        }
        withdrawalAllowance[recipient] = amount;
        emit WithdrawalApproved(recipient, amount);
    }
    
    
    function withdrawTreasure(uint256 amount) public {

        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount-= amount;

            withdrawnAmount[msg.sender]+=amount;
            lastWithdrawTime[msg.sender] = block.timestamp;
            hasWithdrawn[msg.sender]=true;
            emit TreasureWithdrawn(msg.sender, amount);
            return;
        }

        require(block.timestamp>=lastWithdrawTime[msg.sender]+cooldownSeconds, "Cooldown active,try later");

        uint256 allowance = withdrawalAllowance[msg.sender];
        
        require(allowance > 0, "You don't have any treasure allowance");
        require(allowance <= treasureAmount||amount<=treasureAmount, "Not enough treasure in the chest");
        require(amount>0,"Withdraw amount must be greater than zero");
        require (amount <= allowance, "Cannot withdraw more than you are allowed"); 
        
        if (maxWithdrawalLimit[msg.sender]>0){
            require(withdrawnAmount [msg.sender]+amount <= maxWithdrawalLimit[msg.sender], "Exceeds Use's max withdrawal limit");
        }

        withdrawalAllowance[msg.sender]=allowance-amount;
        withdrawnAmount[msg.sender]+=amount;
        hasWithdrawn[msg.sender] = true;
        lastWithdrawTime[msg.sender]=block.timestamp;
        treasureAmount -= amount;

        emit TreasureWithdrawn(msg.sender, amount);
        
    }
    
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
        emit WithdrawalStatusReset(user);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address old =owner;
        owner = newOwner;
        emit OwnershipTransferred(old,newOwner);
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}
