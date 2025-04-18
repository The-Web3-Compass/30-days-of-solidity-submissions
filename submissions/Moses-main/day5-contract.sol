// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;



// A contract that simulates a treasure chest
// controlled by an owner. The owner can add 
// treasure, approve withdrawals for specific 
// users, and even withdraw treasure themselves. 
// Other users can attempt to withdraw, but 
// only if the owner has given them an allowance 
// and they haven't withdrawn before. The owner can 
// also reset withdrawal statuses and transfer 
// ownership of the treasure chest. 
// This demonstrates how to create a contract 
// with restricted access using a 'modifier' and msg.sender, 
// similar to how only an admin can perform certain 
// actions in a game or application.


contract AdminOnly {
    address payable public owner;


    mapping(address => bool) public hasWithdrawn;
    mapping(address => bool) public allowedUsers;
    

    constructor() {
        owner = payable (msg.sender);
    }
     
    modifier onlyOwner(){
        require(msg.sender == owner, "Not the owner"); // check if msg.sender is the owner of the contract
        _; 
    }


    // function setTreasure(uint256 treasure)public onlyOwner{
    //     owner.transfer(treasure);// transfer to owner
    // }

    //withdraw from treausre chest for specific user
    modifier withdrawalOnly(){
        require(!hasWithdrawn[msg.sender], "Already withdrawn"); 
        _;  
    }

    // Accept Ether into the contract
    receive() external payable { }

    function approveUser(address user)public onlyOwner{
            
        allowedUsers[user] = true;
    }

    function withdrawTreasure(uint256 withdrawalAmount)public withdrawalOnly {
        require(allowedUsers[msg.sender], "Not Approved");
        require(address(this).balance >= withdrawalAmount, "Not enough funds in chest");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        hasWithdrawn[msg.sender] = true;
        payable(msg.sender).transfer(withdrawalAmount);
    }

    function withdrawTreasureForUser (address payable user, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds");
        user.transfer(amount);
    }
    
    function resetWithdrawalStatus(address user)public onlyOwner{
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require (newOwner != address(0), "You cannot give yourself the ownership"); // ensure the owner of the contract 
        owner = newOwner;
    
    }
}