// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* a owner controlled treasure chest, the owner can:
   - add treasure to the chest
   - set the allowance for withdrawals
   - withdraw treasure from the chest*/

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;//checking if has withdrawn
    
    // to set the the owner
    constructor() {
        owner = msg.sender;
    }
    
    // Modifier for owner-only functions,is a pre-check
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");//the part after"," writes the opposite
        _;//a pause mark, if it contradicts to the above, pause the process
    }
    
    // Only the owner can add treasure
    function addTreasure(uint256 amount) public onlyOwner { //here call the modifier,if it passes, continues
        treasureAmount += amount;
    }
    
    // Only the owner can approve withdrawals
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");//the amount cannot exceed the treasure amount
        withdrawalAllowance[recipient] = amount;
    }
    
    
    // one can only attempt to withdraw with enough treasure
    function withdrawTreasure(uint256 amount) public {

        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasure available");
            treasureAmount-= amount;
            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        
        //different conditions for a person come to withdraw
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed"); // condition to check if user is withdrawing more than allowed
        
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
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
