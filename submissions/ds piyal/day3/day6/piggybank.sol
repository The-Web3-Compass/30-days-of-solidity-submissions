// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract piggyBank {

    address public bankManager;
    address[] public members;

    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastWithdrawTime;

    uint256 public cooldownTime = 1 days; 
    uint256 public maxWithdrawLimit = 1 ether; 

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }

    modifier onlyBankManager() {
        require(bankManager == msg.sender, "Access Denied, not bank manager!");
        _;
    }

    modifier onlyRegisteredMembers() {
        require(registeredMembers[msg.sender], "You are not registered as a member");
        _;
    }

    function addMember(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != bankManager, "Cannot add yourself as a member");
        require(!registeredMembers[_member], "Already registered as a member");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }

    function deposit(uint256 _amount) public onlyRegisteredMembers {
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] += _amount;
    }

    function depositAmountEther() public payable onlyRegisteredMembers {
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public onlyRegisteredMembers {
        require(_amount > 0, "Invalid amount");
        require(_amount <= balance[msg.sender], "Insufficient funds");
        require(_amount <= maxWithdrawLimit, "Exceeds max withdrawal limit");
        require(block.timestamp >= lastWithdrawTime[msg.sender] + cooldownTime, "Cooldown not finished");

        balance[msg.sender] -= _amount;
        lastWithdrawTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(_amount);
    }

    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");
        return balance[_member];
    }

    function setCooldownTime(uint256 _cooldown) public onlyBankManager {
        cooldownTime = _cooldown;
    }

    function setMaxWithdrawLimit(uint256 _limit) public onlyBankManager {
        maxWithdrawLimit = _limit;
    }

    receive() external payable {
        require(registeredMembers[msg.sender], "Only registered members can send Ether");
        balance[msg.sender] += msg.value;
    }
}
