// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    // State variables
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    
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
    }
    
    // Only the owner can approve withdrawals
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }
    
    
    // Anyone can attempt to withdraw, but only those with allowance will succeed
    function withdrawTreasure(uint256 amount) public {

        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount-= amount;

            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        
        // Check if user has an allowance and hasn't withdrawn yet
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed"); // condition to check if user is withdrawing more than allowed
        
        // Mark as withdrawn and reduce treasure
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
        
    }
    
    // Only the owner can reset someone's withdrawal status
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // Only the owner can transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}