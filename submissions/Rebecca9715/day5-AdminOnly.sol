// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasureChest {
    address public owner; // 宝箱所有者
    uint256 public treasureAmount; // 宝箱中的宝藏数量
    mapping(address => uint256) public allowedAmount; // 用户被批准的提取额度
    mapping(address => bool) public hasWithdrawn; // 用户是否已经提取过
    address[] private allowedUsers; // 存储被批准过额度的用户地址

    // 构造函数，设置合约所有者
    constructor() {
        owner = msg.sender;
    }

    // 修饰器，确保只有所有者可以调用某些函数
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // 所有者添加宝藏
    function addTreasure(uint256 amount) external onlyOwner {
        treasureAmount += amount;
    }

    // 所有者为特定用户批准提取额度
    function approveWithdrawal(address user, uint256 amount) external onlyOwner {
        allowedAmount[user] = amount;
        // 如果用户之前未被批准过额度，将其加入列表
        if (amount > 0 && allowedAmount[user] == amount) {
            allowedUsers.push(user);
        }
    }

    // 所有者自己提取宝藏
    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure");
        treasureAmount -= amount;
    }

    // 其他用户尝试提取宝藏
    function userWithdraw() external {
        uint256 allowed = allowedAmount[msg.sender];
        require(allowed > 0, "No withdrawal allowed");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(allowed <= treasureAmount, "Not enough treasure");

        treasureAmount -= allowed;
        hasWithdrawn[msg.sender] = true;
    }

    // 所有者重置提取状态
    function resetWithdrawalStatus() external onlyOwner {
        for (uint256 i = 0; i < allowedUsers.length; i++) {
            hasWithdrawn[allowedUsers[i]] = false;
        }
    }

    // 所有者转移宝箱所有权
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }
}