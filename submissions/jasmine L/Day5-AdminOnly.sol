// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner; // 任何人可以验证竞拍
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawAllowance; // 任何人都可以看到竞拍
    mapping (address => bool) public hasWithdraw;

    constructor(){
        owner = msg.sender;
    }

    modifier OnlyOwner(){
        require(msg.sender==owner, "Access denied: Only the owner can perform this action");
        _;
    }

    function  addTreasure(uint256 _amount) public OnlyOwner{
        treasureAmount += _amount;
    }

     function approveWithdrawal (address recipent, uint256 amount) public OnlyOwner{
         require(amount<=treasureAmount, "Not enough treasure");
         withdrawAllowance[recipent] = amount;

     }
     
     function withdrawTreasure(uint256 amount) public {
        if(msg.sender==owner){
           require(amount<=treasureAmount, "Not enough treasure");
           treasureAmount -= amount;
           return; 
        }
        uint256 allowance = withdrawAllowance[msg.sender];
        require(allowance > 0, "No allowance");
        require(!hasWithdraw[msg.sender], "Already withdraw");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
     }
     function resetWithdrawalStatus(address user) public OnlyOwner{
        hasWithdraw[user]=false;
     }
     function transferOwnership(address newOwner) public OnlyOwner{
        require(newOwner!=address(0),"Invalid address!");
        owner = newOwner;
     }
     function getTreasureDetails() public view OnlyOwner returns(uint256){
        return treasureAmount;
     }
}