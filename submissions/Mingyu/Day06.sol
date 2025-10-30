// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    address public bankManager;
    address[] public members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastWithdrawalTime; // 记录上次提款时间
    mapping(address => uint256) public withdrawalLimit; // 设置每个成员的最大提款额度

    uint256 public cooldownPeriod = 1 days;  // 设置冷却期：1天
    uint256 public maxWithdrawalLimit = 10 ether; // 设置最大提款额度

    event MemberAdded(address indexed member);
    event Deposit(address indexed member, uint256 amount);
    event Withdrawal(address indexed member, uint256 amount);
    event WithdrawalApproved(address indexed member, uint256 amount);

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }

    modifier canWithdraw(address _member, uint256 _amount) {
        require(block.timestamp >= lastWithdrawalTime[_member] + cooldownPeriod, "Cooldown period has not passed yet.");
        require(balance[_member] >= _amount, "Insufficient balance");
        require(_amount <= withdrawalLimit[_member], "Amount exceeds withdrawal limit");
        _;
    }

    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
        emit MemberAdded(_member);
    }

    function getMembers() public view returns(address[] memory) {
        return members;
    }

    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawAmount(uint256 _amount) public onlyRegisteredMember canWithdraw(msg.sender, _amount) {
        balance[msg.sender] -= _amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;  // 更新提款时间
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");
        return balance[_member];
    }

    // Only bank manager can approve withdrawals
    function approveWithdrawal(address _member, uint256 _amount) public onlyBankManager {
        require(registeredMembers[_member], "Member not registered");
        require(balance[_member] >= _amount, "Insufficient balance");
        balance[_member] -= _amount;
        lastWithdrawalTime[_member] = block.timestamp;
        payable(_member).transfer(_amount);
        emit WithdrawalApproved(_member, _amount);
    }

    // Set maximum withdrawal limit for each member
    function setWithdrawalLimit(address _member, uint256 _limit) public onlyBankManager {
        withdrawalLimit[_member] = _limit;
    }

    // Allow bank manager to withdraw any funds if needed
    function bankManagerWithdraw(uint256 _amount) public onlyBankManager {
        require(address(this).balance >= _amount, "Insufficient contract balance");
        payable(bankManager).transfer(_amount);
    }
}