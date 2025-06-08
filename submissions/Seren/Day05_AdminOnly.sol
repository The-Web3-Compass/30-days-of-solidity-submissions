// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;
    address public preOwner;
    uint256 public treasureAmount;
    mapping(address=>uint256) public withdrawAllowance;
    mapping(address=>bool)public hasWithdrawn;
    mapping(address=>uint256) public accWithdrawAllowance;
    uint256 public cooldownTimer = 10;
    uint256 public lastTimer;
    uint256 public constant MAX_WITHDRAW = 1000;


    event TreasureAdded(address indexed owner, uint256 amount);
    event TreasureWithdrawn(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    constructor(){
        owner = msg.sender;
        preOwner = owner;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Access denied");
        _;
    }

    function addTreasure(uint256 amount)public onlyOwner{
        treasureAmount += amount;
        emit TreasureAdded(msg.sender, amount);
    }

    // Only the owner can approve withdrawals
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        require(amount+accWithdrawAllowance[recipient] <= MAX_WITHDRAW,"Amount exceeds maximum withdrawal limit");
        withdrawAllowance[recipient] = amount;
        accWithdrawAllowance[recipient] += amount;
    }
    
    
    // Anyone can attempt to withdraw, but only those with allowance will succeed
    function withdrawTreasure(uint256 amount) public {
        require(block.timestamp >= cooldownTimer + lastTimer,"Must wait for cooldown");

        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount-= amount;
            emit TreasureWithdrawn(msg.sender, amount);
            return;
        }
        uint256 allowance = withdrawAllowance[msg.sender];
        
        // Check if user has an allowance and hasn't withdrawn yet
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed"); // condition to check if user is withdrawing more than allowed
        
        // Mark as withdrawn and reduce treasure
        hasWithdrawn[msg.sender] = true;
        lastTimer = block.timestamp;
        treasureAmount -= allowance;
        withdrawAllowance[msg.sender] = 0;

        emit TreasureWithdrawn(msg.sender, amount);
        
    }

    function checkWithdrawalStatus()public view returns(uint256, bool){
        return (withdrawAllowance[msg.sender], hasWithdrawn[msg.sender]);
    }
    
    // Only the owner can reset someone's withdrawal status
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // Only the owner can transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        preOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(owner,newOwner);
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}   