// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    // State variables
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    
    // Sets the contract deployer as the initial owner
    constructor() {
        owner = msg.sender;
    }
    
    //  Restricts access to owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }
    
    // Allows the owner to increase the total treasure
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }
    
    // Allows the owner to approve a specific withdrawal amount for a user
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }
    
    
    // Allows users to withdraw their approved amount, enforcing rules to prevent double withdrawal
    function withdrawTreasure(uint256 amount) public {

        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount-= amount;

            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        
        // Ensures the user has an approved allowance and hasn't already withdrawn
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed"); // condition to check if user is withdrawing more than allowed
        
        // Records the withdrawal and updates balances
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;
        
    }
    
    // Allows the owner to reset a user's withdrawal status
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // Allows the current owner to transfer ownership to another address
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    // Returns the current treasure amount; owner-only access
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}