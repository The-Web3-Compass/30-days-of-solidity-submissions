// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;
    uint256 public treasureAmt;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) hasWithdrawn;

    constructor(){
        owner = msg.sender;
    }
    modifier OnlyOwner(){
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }
    function addTrresure(uint256 amt) public OnlyOwner{
        treasureAmt += amt;
    }
    function approveWithdrawal(address recipient, uint256 amt) public OnlyOwner{
        require(amt <= treasureAmt, "Insufficient funds in the contract");
        withdrawalAllowance[rcpt] = amt
    }
    function withdrawalTreasure(uint256 amt) public {
        if(msg.sender == owner){
            require(amt <= tresureAmt,"Insufficient funds in the contract");
            treasureAmt -= amt;
            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance. Get an approval for allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmt ,"Not enought treasure in the chest");
        require(amt <= allowance ,"Not enought treasure in the chest");

        hasWithdrawn[msg.sender] = true;
        tresureAmt -= allowance;
        withdrawalAllowance[msg.sender] = 0;
    }
    // reset the allowance
    function resetWithdrawalStatus(address user) public OnlyOwner{
        hasWithdrawn[user] = false;
    }
    function transferOwnership(address newOwner) public OnlyOwner{
        require(newOwner != address(0) , "Invalid user");
        owner = newOwner;
    }
    function getAllowanceDetail() public view OnlyOwner return(uint256){
        return treasureAmt;
    }
}