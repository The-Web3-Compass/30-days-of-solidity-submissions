// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    address public bankManager;
    address[] public members;

    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) private balance;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public dailyWithdrawn;
    mapping(address => uint256) public pendingWithdrawals; // 待审批取款请求

    uint256 public cooldownTime = 10 minutes; // 默认冷却期
    uint256 public dailyLimit = 1 ether;      // 默认每日上限
    bool public approvalRequired = false;     // 是否开启审批模式

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }

    // ===================== 基础功能 =====================
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(!registeredMembers[_member], "Member already registered");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }

    // 用户存入 ETH
    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }

    // ===================== 提现功能 =====================
    /// @notice 用户发起取款请求（根据审批机制自动或待批）
    function requestWithdraw(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");

        // 检查冷却期
        require(block.timestamp >= lastWithdrawTime[msg.sender] + cooldownTime, "Please wait for cooldown");

        // 检查每日限额
        if (block.timestamp / 1 days == lastWithdrawTime[msg.sender] / 1 days) {
            // 同一天
            require(dailyWithdrawn[msg.sender] + _amount <= dailyLimit, "Exceeds daily withdrawal limit");
        } else {
            // 新的一天
            dailyWithdrawn[msg.sender] = 0;
        }

        if (approvalRequired) {
            // 开启审批：仅提交申请
            pendingWithdrawals[msg.sender] = _amount;
        } else {
            // 未开启审批：自动执行取款
            _processWithdraw(msg.sender, _amount);
        }
    }

    /// @notice 管理员审批通过后执行实际取款
    function approveWithdrawal(address _member) public onlyBankManager {
        uint256 amount = pendingWithdrawals[_member];
        require(amount > 0, "No pending withdrawal request");

        _processWithdraw(_member, amount);
        pendingWithdrawals[_member] = 0;
    }

    /// @dev 内部函数：真正执行转账逻辑
    function _processWithdraw(address _member, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Contract has insufficient funds");

        balance[_member] -= _amount;
        lastWithdrawTime[_member] = block.timestamp;
        dailyWithdrawn[_member] += _amount;

        payable(_member).transfer(_amount);
    }

    // ===================== 管理员控制 =====================
    function setCooldownTime(uint256 minutesAmount) public onlyBankManager {
        cooldownTime = minutesAmount * 1 minutes;
    }

    function setDailyLimit(uint256 limitWei) public onlyBankManager {
        dailyLimit = limitWei;
    }

    function toggleApprovalRequired(bool _status) public onlyBankManager {
        approvalRequired = _status;
    }

    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");
        return balance[_member];
    }

    // 管理员提取误转入的资金（保护措施）
    function emergencyWithdraw(address payable to, uint256 amount) public onlyBankManager {
        require(address(this).balance >= amount, "Not enough funds");
        to.transfer(amount);
    }

    // 合约接收 ETH 的回退函数
    receive() external payable {}
}