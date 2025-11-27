// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    // 状态变量
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;

    // 在构造函数中设置合约属主
    constructor() {
        owner = msg.sender;
    }

    // 定义修饰符实现访问控制
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }

    // 合约属主可以添加宝藏
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    // 合约属主可以批准提取
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }

    // 任何人都能尝试提取, 但只有有提取额度才可能成功
    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            // 合约属主可以提取任何数量的宝藏
            require(amount <= treasureAmount, "Not enough treasure available for this action.");
            treasureAmount -= amount;
            
            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];

        // 检查用户是否有额度且尚未提取过
        require(allowance > 0, "You don't have any treasure allowance.");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure.");
        require(allowance <= treasureAmount, "Not enough treasure in the chest.");
        require(allowance >= amount, "Cannot withdraw more than you are allowed.");

        // 更新状态变量
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] = 0;

    }

    // 合约属主可重置提取状态
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    // 合约属主可以转移合约所有权
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    // 查询宝藏数量明细
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}