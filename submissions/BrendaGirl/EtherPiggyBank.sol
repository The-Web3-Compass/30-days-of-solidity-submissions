// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {

    // === STATE VARIABLES ===
    address public bankManager;
    address[] public members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;

    // === CONSTRUCTOR ===
    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }

    // === MODIFIERS ===
    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }

    // === FUNCTIONS ===

    // Add a new member to the piggy bank
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    // View all members
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    // Simulate deposit with dummy units (not real ETH)
    function deposit(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] += _amount;
    }

    // Simulate withdrawal with dummy units
    function withdraw(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }

    // Real Ether deposit
    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }

}
