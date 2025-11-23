// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PiggyBank{
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;
    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
    }
    modifier onlyBankManager() {
        require(msg.sender == bankManager, "only bank manager can perform this action");
        _;
    }
    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        members.push(_member);
        registeredMembers[_member] = true;
    }
    function getMembers() public view returns (address[] memory) {
        return members;
    }
    function deposit(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Amount must be greater than zero");
        balance[msg.sender] += _amount;
    }
    function withdraw(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Amount must be greater than zero");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }
    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Amount must be greater than zero");
        balance[msg.sender] += msg.value;
    }
    function withdrawAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Amount must be greater than zero");
        require(balance[msg.sender] >= msg.value, "Insufficient balance");
        balance[msg.sender] -= msg.value;
    }

}