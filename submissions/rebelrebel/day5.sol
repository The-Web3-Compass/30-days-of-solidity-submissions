// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => uint) public lastWithdrawalTime;
    uint public constant COOLDOWN_PERIOD = 5 minutes;

    event TreasureAdded(address indexed operator, uint256 amount);
    event TreasureWithdrawn(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    uint public constant MAX_WITHDRAWAL_PER_USER = 10 ether;

    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only owner can perform this action");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
        emit TreasureAdded(msg.sender, amount);
    }

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        require(amount <= MAX_WITHDRAWAL_PER_USER, "Amount exceeds max limit per user.");
        
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure() public {
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance");
        
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + COOLDOWN_PERIOD, "Cooldown period is still active. Please wait.");
        
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
        lastWithdrawalTime[msg.sender] = block.timestamp;

        emit TreasureWithdrawn(msg.sender, allowance);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function getUserStatus(address _user) public view returns (uint256 allowance, uint256 timeUntilNextWithdrawal) {
        allowance = withdrawalAllowance[_user];
        
        uint nextAvailableTime = lastWithdrawalTime[_user] + COOLDOWN_PERIOD;
        if (block.timestamp < nextAvailableTime) {
            timeUntilNextWithdrawal = nextAvailableTime - block.timestamp;
        } else {
            timeUntilNextWithdrawal = 0;
        }
    }
}