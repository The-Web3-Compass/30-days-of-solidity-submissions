// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


// 1️⃣ Set up ownership and Constructor sets the deployer as the initial owner

// 2️⃣ onlyOwner modifier

// 3️⃣ Function for owner to approve a user (mapping address => uint)

// 4️⃣ mapping(address => bool) hasWithdrawn — tracks if a user already withdrew

// 5️⃣ withdraw() function:
//     ✅ Only owner or approved user can call
//     ✅ Must not have withdrawn before (hasWithdrawn[msg.sender] == false)
//     ✅ Transfer amount to user
//     ✅ Mark hasWithdrawn[msg.sender] = true

// 6️⃣ Function for owner to reset a user's withdrawal status
//     ✅ This sets hasWithdrawn[user] = false

// 7️⃣ Function for owner to transfer ownership


contract AdminOnly {

    address public owner;

    mapping(address => bool) public approvedUser;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an Owner");
        _;
    }

    // Owner deposits ETH treasure into contract
    function deposit() public payable onlyOwner {
        // No need to update manual balance — ETH goes straight to contract
    }

    function approveUser(address user) public onlyOwner {
        approvedUser[user] = true;
    }

    function withdraw(uint _amount) public {
        require(msg.sender == owner || approvedUser[msg.sender], "Not allowed");
        require(!hasWithdrawn[msg.sender], "Already Withdrawn");
        require(_amount <= address(this).balance, "Not enough treasure!");
        
        hasWithdrawn[msg.sender] = true;
        payable(msg.sender).transfer(_amount);
    }

    function resetWithdrawal(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid Address");
        owner = _newOwner;
    }
}
