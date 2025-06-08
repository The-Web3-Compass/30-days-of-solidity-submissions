// SPDX-License-Identifier: MIT

contract AdminOnly{

address public owner;

//sets whoever deploy the contract first to be the owner
 constructor(){
    owner = msg.sender;
}
//only the owner can modify the contract, otherwise access denied
modifier onlyOwner(){
    require (msg.sender == owner, "Access Denied: Unauthorized");
    _;
}
uint256 public treasureAmount;

function addTreasure (uint256 amount) public onlyOwner{
    treasureAmount += amount;
}
//approve others to withdraw
mapping (address => uint256) public withdrawAllowance; 

function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
    require (amount <= treasureAmount, "Not enough treasure available");
    withdrawAllowance[recipient] = amount;
}
mapping (address => bool) public hasWithdrawn; 

function withdraw (uint256 amount) public{
    if (msg.sender == owner){
        require(amount <= treasureAmount, "Not enough treausre available for this action");
        treasureAmount -= amount;
        return;
    }
    uint256 allowance = withdrawAllowance[msg.sender];
    require (allowance >0, "You don't have any treasure allowance");
    require (!hasWithdrawn[msg.sender],"You already withdrew for this action");
    require (allowance < treasureAmount,"Not enough treasure in the chest");

    hasWithdrawn[msg.sender] = true;
    treasureAmount -= allowance; 
    withdrawAllowance[msg.sender] = 0;
}
function resetWithdrawStatus(address user) public onlyOwner{
    hasWithdrawn[user] = false; 
}
function transferOwnership(address newOwner) public onlyOwner{
    require(newOwner != address(0),"Invalid Address");
    owner = newOwner;
}
function getTreasureDetails() public view onlyOwner returns (uint256){
    return treasureAmount;
}
}

