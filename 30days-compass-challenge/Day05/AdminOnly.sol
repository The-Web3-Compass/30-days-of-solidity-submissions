// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract AdminOnly {
    // State variables
    address public owner;
    uint256 public treasureAmount;
    
    // Track user allowances and withdrawal status
    mapping(address => uint256) public allowances;
    mapping(address => bool) public hasWithdrawn;
    
    // Events for tracking actions
    event TreasureAdded(uint256 amount, uint256 newTotal);
    event AllowanceGranted(address indexed user, uint256 amount);
    event TreasureWithdrawn(address indexed user, uint256 amount);
    event WithdrawalStatusReset(address indexed user);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Custom errors (gas efficient)
    error NotOwner();
    error NoAllowance();
    error AlreadyWithdrawn();
    error InsufficientTreasure();
    error InvalidAmount();
    error InvalidAddress();
   
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }
    
   
    constructor() {
        owner = msg.sender;
    }
   
    function addTreasure(uint256 amount) external onlyOwner {
        if (amount == 0) {
            revert InvalidAmount();
        }
        
        treasureAmount += amount;
        emit TreasureAdded(amount, treasureAmount);
    }
    
   
    function approveWithdrawal(address user, uint256 amount) external onlyOwner {
        if (user == address(0)) {
            revert InvalidAddress();
        }
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (amount > treasureAmount) {
            revert InsufficientTreasure();
        }
        
        allowances[user] = amount;
        emit AllowanceGranted(user, amount);
    }
   
    function withdrawTreasure() external {
        uint256 allowance = allowances[msg.sender];
        
        if (allowance == 0) {
            revert NoAllowance();
        }
        if (hasWithdrawn[msg.sender]) {
            revert AlreadyWithdrawn();
        }
        if (allowance > treasureAmount) {
            revert InsufficientTreasure();
        }
        
        // Update state before transfer (CEI pattern)
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        allowances[msg.sender] = 0;
        
        emit TreasureWithdrawn(msg.sender, allowance);
        
        // In a real implementation, you'd transfer ETH or tokens here
        // For this example, we're just tracking the treasure amount
    }
    
   
    function ownerWithdraw(uint256 amount) external onlyOwner {
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (amount > treasureAmount) {
            revert InsufficientTreasure();
        }
        
        treasureAmount -= amount;
        emit TreasureWithdrawn(owner, amount);
    }
    
    function resetWithdrawalStatus(address user) external onlyOwner {
        if (user == address(0)) {
            revert InvalidAddress();
        }
        
        hasWithdrawn[user] = false;
        emit WithdrawalStatusReset(user);
    }
   
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidAddress();
        }
        
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    function checkWithdrawalStatus(address user) external view returns (bool canWithdraw, uint256 allowance) {
        allowance = allowances[user];
        canWithdraw = (allowance > 0 && !hasWithdrawn[user] && allowance <= treasureAmount);
    }
    
    function getInfo() external view returns (address currentOwner, uint256 totalTreasure) {
        return (owner, treasureAmount);
    }
}