// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    uint public cooldownTime;
    uint256 public withdrawLimit;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawalTotal;
    mapping(address => bool) public isApproved;

    event TreasureAdded(uint256 amount);
    event WithdrawalApproved(address recipient, uint256 amount);
    event TreasureWithdrawn(address recipient, uint256 amount);
    event OwnershipTransferred(address newOwner);
    
    constructor(uint _cooldownTime, uint256 _withdrawLimit) {
        owner = msg.sender;
        cooldownTime = _cooldownTime;
        withdrawLimit = _withdrawLimit;
    }
    
    modifier onlyOwner() {
      require(msg.sender == owner,  "Access denied: Only the owner can perform this action");
        _;
    }
    
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
        emit TreasureAdded(amount);
    }
    
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount<=treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
        isApproved[recipient] = true;
        emit WithdrawalApproved(recipient, amount);
    }
    
    function withdrawTreasure(uint256 amount) public {
        if(msg.sender == owner) {
            require(amount<treasureAmount, "Not enough treasure.");
            treasureAmount -= amount;
            hasWithdrawn[msg.sender] = true;
            emit TreasureWithdrawn(owner, amount);
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance.");
        require(allowance <= treasureAmount, "Not enough treasure in the chest.");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure.");
        require(amount <= allowance, "Cannot withdraw more than you are allowed."); 
        require(withdrawalTotal[msg.sender]+amount<=withdrawLimit, "You have reached your withdrawal limit.");
        require(block.timestamp>lastWithdrawalTime[msg.sender]+cooldownTime, "Please wait before making another withdrawal");
        treasureAmount -= amount;
        hasWithdrawn[msg.sender] = true;
        withdrawalAllowance[msg.sender] = 0;
        withdrawalTotal[msg.sender] += amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        emit TreasureWithdrawn(msg.sender, amount);
    }
    
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
        isApproved[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");

        owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    function hasUserWithdrawn() public view returns(bool) {
        return hasWithdrawn[msg.sender];
    }

    function isUserApproved() public view returns(bool) {
        return isApproved[msg.sender];
    }
}