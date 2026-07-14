// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract AdmainOnly{

     address public owner;
     uint256 public treasureAmount;
     mapping(address => uint256) public withdrawalAllowance;
     mapping(address => bool) hasWithdrawn;

     constructor(){

        owner = msg.sender;

        }
        modifier OnlyOwner(){
            require(msg.sender == owner,"Access denied:Only the owner can perform this action");
            _;
        } 
        function addTreasure(uint256 amount) public OnlyOwner{
            //require(msg.sender == owner,"Access denied:Only the owner can perform this action");
        
            //if this condition passes continue to function logic,
            treasureAmount+=amount;

        }
     
function approveWithdrawl(address recipient,uint256 amount)public OnlyOwner{
    require(amount <= treasureAmount,"Insufficient funds in the contract");
    withdrawalAllowance[recipient] = amount;
}

function withdrawTreasure(uint256 amount)public {
    if(msg.sender == owner){
       require(amount <= treasureAmount,"Insufficient funds in the contract");
       treasureAmount -= amount;
       return;
    }

    uint256 allowance = withdrawalAllowance[msg.sender];

    require(allowance > 0,"You do not have any treasure allowance");
    require(!hasWithdrawn[msg.sender],"You have already withdrawn your");
    require(allowance <= treasureAmount, "Not enough treasure in the chest");

    hasWithdrawn[msg.sender] = true;
    treasureAmount -= allowance;
    withdrawalAllowance[msg.sender] = 0;
    }
  
    // Only the owner can reset someone's withdrawal status
    function resetWithdrawalStatus(address user) public OnlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // Only the owner can transfer ownership
    function transferOwnership(address newOwner) public OnlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    function getTreasureDetails() public view OnlyOwner returns (uint256) {
        return treasureAmount;
    }
}
