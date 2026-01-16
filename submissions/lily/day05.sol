// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;    

// 只有管理员能控制
contract AdminOnly {
    address public owner;
    // 构造函数只在部署时运行一次
    constructor() {
        owner = msg.sender;
    }
    // 通过修饰符实现可复用的访问控制
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only OWNER can take action.");
        _; // 占位符，权限检查之后的函数主体将被插入的位置
    }

    uint256 public treasureAmount;
    function addTreasure(uint256 amount) public onlyOwner { // onlyOwner 修饰符确保只有Owner可以操作
        treasureAmount += amount;
    }

    mapping(address => uint256) public withdrawalAllowance;

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "No enough treasure available");
        withdrawalAllowance[recipient] = amount; // 设置 recipient 提取限额
    }

    mapping(address => bool) public hasWithdrawn;

    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) { // 管理者可任意提取
            require(amount <= treasureAmount, "no enough treasure available");
            treasureAmount -= amount;
            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "no allowance");
        require(!hasWithdrawn[msg.sender], "you have already withdrawn your treasure");
        require(allowance <= treasureAmount, "no enough treasure available");

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance; // 一次提取最高限额
        withdrawalAllowance[msg.sender] = 0;
    }

    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) { // 只有 owner 能查看
        return treasureAmount;
    }

    // 冷却时间计时器
    // 
}