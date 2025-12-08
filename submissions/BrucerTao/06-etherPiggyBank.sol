// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank {
    address public bankManager;  //银行管理者
    address[] public members;   //成员列表
    mapping(address => bool) public registeredMembers; //成员->是否批准
    mapping(address => uint256) public balance; //成员->余额

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registere);
    }

    //添加新成员
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a memeber");
        require(!registeredMembers[_member], "Memeber already registered");

        registeredMembers[_member] = true;
        memeber.push(_member);

    }

    //查看成员
    function getMemebers() public view returns(address[] memory) {
        return memeber;

    }

    //模拟存储
    function deposit(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] += _amount;

    }

    //提取存储
    function withdraw(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;

    }

    //模拟存入以太币
    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;

    }

    // 提现以太币到用户地址
    function withdrawEther(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        // 先更新余额，防止重入
        balance[msg.sender] -= _amount;
        // 向用户转账以太币
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Ether transfer failed");
    }


    // -------- 扩展功能：限制、冷却时间与审批系统（不修改现有函数） --------

    // 冷却时间（针对以太币提现）
    uint256 public withdrawCooldownTime = 5 minutes; // 默认5分钟
    mapping(address => uint256) public lastWithdrawEtherTime; // 上次以太提现时间

    // 设置以太币提现冷却时间（仅银行管理者）
    function setWithdrawCooldownTime(uint256 newCooldownTime) public onlyBankManager {
        withdrawCooldownTime = newCooldownTime;
    }

    // 含冷却时间检查的以太币提现（保持原函数不变，提供替代接口）
    function withdrawEtherWithCooldown(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        require(
            block.timestamp >= lastWithdrawEtherTime[msg.sender] + withdrawCooldownTime,
            "Cooldown period not over"
        );

        // 更新余额与冷却时间，再转账
        balance[msg.sender] -= _amount;
        lastWithdrawEtherTime[msg.sender] = block.timestamp;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // 每日提现限额（全局与用户级）
    uint256 public globalDailyWithdrawLimit; // 为0表示不限制
    mapping(address => uint256) public userDailyWithdrawLimit; // 为0表示使用全局限制或不限制
    mapping(address => uint256) public dayWithdrawnAmount; // 当天已提现总额
    mapping(address => uint256) public lastWithdrawDay; // 上次提现所在天索引

    // 设置全局每日提现限额（仅银行管理者）
    function setGlobalDailyWithdrawLimit(uint256 limit) public onlyBankManager {
        globalDailyWithdrawLimit = limit;
    }

    // 设置用户每日提现限额（仅银行管理者）
    function setUserDailyWithdrawLimit(address user, uint256 limit) public onlyBankManager {
        userDailyWithdrawLimit[user] = limit;
    }

    // 含每日限额检查的以太币提现
    function withdrawEtherWithLimit(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");

        uint256 dayIndex = block.timestamp / 1 days;
        if (lastWithdrawDay[msg.sender] != dayIndex) {
            dayWithdrawnAmount[msg.sender] = 0;
            lastWithdrawDay[msg.sender] = dayIndex;
        }

        uint256 limit = userDailyWithdrawLimit[msg.sender] > 0
            ? userDailyWithdrawLimit[msg.sender]
            : globalDailyWithdrawLimit;
        if (limit > 0) {
            require(dayWithdrawnAmount[msg.sender] + _amount <= limit, "Exceeds daily limit");
        }

        balance[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Ether transfer failed");
        dayWithdrawnAmount[msg.sender] += _amount;
    }

    // 审批系统：用户申请，管理者批准/撤销，按审批额度提现
    mapping(address => uint256) public requestedWithdrawAmount; // 用户申请的额度
    mapping(address => uint256) public approvedWithdrawAmount;  // 已批准的额度
    mapping(address => bool) public isWithdrawApproved;         // 是否获得批准

    // 用户发起提现审批申请
    function requestWithdrawApproval(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        requestedWithdrawAmount[msg.sender] = _amount;
        isWithdrawApproved[msg.sender] = false;
    }

    // 银行管理者批准用户的提现申请
    function approveWithdraw(address user, uint256 amount) public onlyBankManager {
        require(user != address(0), "Invalid address");
        require(requestedWithdrawAmount[user] == amount, "Request mismatch");
        require(balance[user] >= amount, "Insufficient balance");
        approvedWithdrawAmount[user] = amount;
        isWithdrawApproved[user] = true;
    }

    // 银行管理者撤销用户的提现审批
    function revokeWithdrawApproval(address user) public onlyBankManager {
        require(user != address(0), "Invalid address");
        isWithdrawApproved[user] = false;
        approvedWithdrawAmount[user] = 0;
        requestedWithdrawAmount[user] = 0;
    }

    // 按审批额度进行提现
    function withdrawEtherWithApproval(uint256 _amount) public onlyRegisteredMember {
        require(isWithdrawApproved[msg.sender], "Not approved");
        require(_amount > 0, "Invalid amount");
        require(_amount <= approvedWithdrawAmount[msg.sender], "Exceeds approved amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");

        balance[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Ether transfer failed");

        approvedWithdrawAmount[msg.sender] -= _amount;
        if (approvedWithdrawAmount[msg.sender] == 0) {
            isWithdrawApproved[msg.sender] = false;
            requestedWithdrawAmount[msg.sender] = 0;
        }
    }

    // 视图辅助：查看限额、冷却与审批状态
    function getWithdrawLimitStatus(address user) public view returns (uint256 limit, uint256 withdrawnToday, uint256 remaining){
        uint256 dayIndex = block.timestamp / 1 days;
        uint256 used = dayWithdrawnAmount[user];
        if (lastWithdrawDay[user] != dayIndex) {
            used = 0;
        }

        uint256 effective = userDailyWithdrawLimit[user] > 0
            ? userDailyWithdrawLimit[user]
            : globalDailyWithdrawLimit;
        uint256 rem = effective > 0 ? (effective > used ? effective - used : 0) : type(uint256).max;
        return (effective, used, rem);
    }

    function getWithdrawCooldownStatus(address user) public view returns (uint256 cooldownEndsAt, uint256 secondsRemaining){
        uint256 endTime = lastWithdrawEtherTime[user] + withdrawCooldownTime;
        uint256 remaining = block.timestamp >= endTime ? 0 : (endTime - block.timestamp);
        return (endTime, remaining);
    }

    function getWithdrawApprovalStatus(address user) public view returns (bool approved, uint256 approvedAmount_, uint256 requestedAmount_){
        return (isWithdrawApproved[user], approvedWithdrawAmount[user], requestedWithdrawAmount[user]);
    }



}