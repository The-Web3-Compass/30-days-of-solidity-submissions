// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true; // we want to ensure only registered members can interact with the piggy bank
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only the bank manager can perform this action.");
        _;
    }
    modifier onlyRegisteredMembers() {
        require(registeredMembers[msg.sender], "Account not found, please register first.");
        _;
    }

    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");

            registeredMembers[_member] = true;
            members.push(_member);
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }

    function deposit(uint256 _amount) public onlyRegisteredMembers {
        require(_amount > 0, "Deposit amount must be greater than zero.");
        balance[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) public onlyRegisteredMembers {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(balance[msg.sender] >= _amount, "Insufficient balance.");
        require(address(this).balance >= _amount, "Contract has insufficient Ether.");
        balance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function depositAmountEther() public payable onlyRegisteredMembers {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balance[msg.sender] += msg.value;
    }
}

// This contract is still missing 
//      a withdrawal function that sends Ether back to users
//      add limits, cooldowns, or approval systems
