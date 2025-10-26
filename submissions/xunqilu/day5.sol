// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _; //placeholder,where the rest of the code in the funtion shoul run
    }
    
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }
    
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }
    
    
    function withdrawTreasure(uint256 amount) public {

        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount-= amount;
            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
            //‘amount<=trasureAmount’ make more sense than ‘allowance <= treasureAmount’ for checking if there are enough treasure in the chest
            //because if the amount user wanna withdraw is lower than allowance and current treasure amount 
            //but the allowance is more than the treasure amount, then the user can not withdraw any money
            //for example, treasure is 5, amount is 2, allowance is 10
        require(allowance >= amount, "Cannot withdraw more than you are allowed"); 
        
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance; //should it be -= amount？
        withdrawalAllowance[msg.sender] = 0; //is this necessary when we already set hasWithdraw to true? if the user's status get reset, 
                                            // then they still can not withdraw any money unless the allowance get reset too
        
    }
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}