// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TheEtherPiggyBank {
    address public bankManager;
    address[] members; #默认是internal
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;
    constructor() {
        bankManager = msg.sender;
        members.push(bankManager);
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only the bank manager can call this function");
        _;
    }
    modifier onlyRegisteredMembers() {
        require(registeredMembers[msg.sender], "Only registered members can call this function");
        _;
    }

    function addMembers(address _member) public onlyBankManager { 
        require(_member != address(0), "Invalid address");
        require(!registeredMembers[_member], "Member is already registered");
        require(_member != msg.sender, "Cannot register yourself as a member");
        members.push(_member);
    }
    function getMenbers() public view returns (address[] memory){
        return members;
    }
    function deposit(uint256 _amount) public onlyRegisteredMembers {
        require(_amount > 0, "Deposit amount must be greater than zero");
        balance[msg.sender] += _amount;
    }
    function withdraw(uint256 _amount) public onlyRegisteredMembers {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }
    function depositAmountEther() public payyable onlyRegisteredMembers {
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }
}