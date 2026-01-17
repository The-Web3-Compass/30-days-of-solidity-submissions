//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {

    //there should be a bank manager who has the certain permissions
    //there should be an array for all members registered
    //a mapping whther they are registered or not
    //a mapping with there balances
    address public bankManager;
    address[] public members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only the bank manager can perform this action");
        _;
    }

    modifier onlyRegistredMember() {
        require(registeredMembers[msg.sender], "Membre not registred");
        _;
    }

    function addMember(address member) public onlyBankManager {
        require(address(0) != member, "Invalid address");
        require(bankManager != member, "Bank manager is already a member");
        require(!registeredMembers[member], "Member has registered");
        members.push(member);
        registeredMembers[member] = true;
    }

    function getMembers() public view returns(address[] memory) {
        return members;
    }

    function deposite(uint256 amount) public onlyRegistredMember {
        require(amount > 0, "Invalid amount");
        balance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public onlyRegistredMember {
        require(amount > 0, "Invalid amount");
        require(amount <= balance[msg.sender], "Insufficient balance");
        balance[msg.sender] -= amount;
    }

    function depositeAmountEther() public payable onlyRegistredMember {
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }

    function withdrawAmountEther(uint256 amount) public payable onlyRegistredMember {
        require(amount > 0, "Invalid amount");
        require(amount <= balance[msg.sender], "Insufficient balance");
        payable(msg.sender).transfer(amount);
        balance[msg.sender] -= amount;
    }

    function getBalance(address member) public view onlyRegistredMember returns(uint256) {
        require(address(0) != member, "Invalid address");
        return balance[member];
    }


}