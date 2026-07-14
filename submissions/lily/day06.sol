// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;    

// 共享数字存钱罐
contract EtherPiggyBank {
    // 加入小组（需获得批准
    // 存钱
    // 查看余额
    // 提取资金

    // 管理者
    address public bankManager;
    // 成员
    address[] members;
    mapping(address => bool) public registeredMembers;
    // 记录每位成员的余额
    mapping(address => uint256) balance;

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender); // 管理者也是第一个成员
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only BANKMANAGER can take this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "MEMBER not registered");
        _;
    }

    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "bankmanager is already a member");
        require(!registeredMembers[_member], "member is already registered");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    // 查看成员 - 所有人都可以
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    function deposit(uint256 _amount) public onlyRegisteredMember() { // 构造函数后面加()也能编译
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) public onlyRegisteredMember() {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }

    // 接受真正的以太币
    function depositAmountEther() public payable onlyRegisteredMember() { // payable 表示该函数可以接收以太币
        require(msg.value > 0, "Invalid amount"); // msg.value 表示用户在交易中发送的以太币数量
        balance[msg.sender] += msg.value;
    }

    // 取现函数
    // 取款限制、冷却期、审批
}