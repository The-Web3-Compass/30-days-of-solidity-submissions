// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

contract AdminOnly {

    // ---------------- VARIABLES ----------------
    address public owner; // the owner of the contract
    address[] public admins;// admins of the contract
    mapping (address => bool) public isAdmin;// check if 
    mapping (address => bool) public users;// approved users of the contract

    uint public treasureAmount; // amount in the treasure 

    mapping(address => uint) public withdrawalAccess; // approval to withdraw
    mapping(address => uint) public withDrawalHistory; // withdrawal history

    // ---------------- CONSTRUCTOR ----------------
    constructor() {
        owner = msg.sender;
    }

    // ---------------- MODIFIERS ----------------
    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner of the contract");
        _;
    }

    modifier onlyApproved() {
        require(withdrawalAccess[msg.sender] > 0, "You're not allowed to withdraw");
        _;
    }

    modifier onlyAdmins() {
       require(msg.sender == owner, "Not an admin");
        _;
    }

    modifier onlyUser() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    // ---------------- FUNCTIONS ----------------

    function addTreasure(uint amount) public onlyOwner {
        treasureAmount = amount + 1;
    }

    function allowWithdrawal(address recipient, uint amount) public onlyOwner {
        require(amount <= treasureAmount, "not enough money in the treasury");
        withdrawalAccess[recipient] = amount;
    }

    function withdrawTreasure(uint amount) public {

        if (msg.sender == owner) {
            require(amount <= treasureAmount, "no sufficient balance");
            treasureAmount -= amount;
            return;
        }

        // regular users
        require(amount <= treasureAmount, "no sufficient balance");
        require(amount <= withdrawalAccess[msg.sender], "withdrawal limit exceeded");

        withdrawalAccess[msg.sender] -= amount;
        treasureAmount -= amount;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner cannot be zero address");
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

// Add a new admin (only owner or existing admins can call)
    function addAdmin(address _newAdmin) public onlyOwner {
    isAdmin[_newAdmin] = true;
    admins.push(_newAdmin);  
    }
}