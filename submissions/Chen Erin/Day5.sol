// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;

    mapping(address => uint256) public withdrawalAllowance;  // 当前批准额度
    mapping(address => bool) public hasWithdrawn;             // 是否已提取（单次）
    mapping(address => uint256) public lastWithdrawTime;      // 上次提取时间
    mapping(address => uint256) public totalWithdrawn;        // 用户累计提取金额
    mapping(address => uint256) public maxWithdrawLimit;      // 每个用户最大提取上限

    uint256 public cooldownTime = 10 minutes; // 默认冷却时间（可修改）

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only owner");
        _;
    }

    // ------------------- 管理员功能 -------------------

    // 添加宝藏（仅计数）
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    // 批准用户可提取的金额
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }

    // 设置冷却时间
    function setCooldownTime(uint256 minutesAmount) public onlyOwner {
        cooldownTime = minutesAmount * 1 minutes;
    }

    // 为用户设置最大提取上限
    function setMaxWithdrawLimit(address user, uint256 limit) public onlyOwner {
        maxWithdrawLimit[user] = limit;
    }

    // 重置用户的“已提取”状态
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    // 转移管理员权限
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    // ------------------- 用户功能 -------------------

    function withdrawTreasure(uint256 amount) public {
        // 检查冷却时间
        require(
            block.timestamp >= lastWithdrawTime[msg.sender] + cooldownTime,
            "You must wait for cooldown period"
        );

        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasure available");
            treasureAmount -= amount;
            lastWithdrawTime[msg.sender] = block.timestamp;
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn this round");
        require(amount <= allowance, "Cannot withdraw more than approved");
        require(amount <= treasureAmount, "Not enough treasure in chest");

        // 检查是否超过用户上限
        uint256 userLimit = maxWithdrawLimit[msg.sender];
        if (userLimit > 0) {
            require(
                totalWithdrawn[msg.sender] + amount <= userLimit,
                "Exceeds your maximum withdrawal limit"
            );
        }

        // 更新状态
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] -= amount;
        totalWithdrawn[msg.sender] += amount;
        lastWithdrawTime[msg.sender] = block.timestamp;
    }

    // 仅管理员可查看宝藏详情
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}