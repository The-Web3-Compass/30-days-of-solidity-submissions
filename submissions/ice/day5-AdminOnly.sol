// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AdminOnly 宝箱合约
/// @author 
/// @notice 控制权限提款、授权、重置状态与所有权
contract AdminOnly {
    /// @notice 当前宝箱的所有者
    address public owner;

    /// @notice 每个用户被授权的提款额度（单位：wei）
    mapping(address => uint256) public allowances;

    /// @notice 每个用户是否已经提取过
    mapping(address => bool) public hasWithdrawn;

    /// @notice 所有曾经授权过的地址（用于状态重置）
    address[] private authorizedUsers;

    /// ========== 事件 ==========
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Withdrawal(address indexed user, uint256 amount);
    event AllowanceSet(address indexed user, uint256 amount);
    event WithdrawStatusReset();
    event Deposit(address indexed from, uint256 amount);

    /// ========== 修饰器 ==========
    /// @notice 仅限所有者执行的操作
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    /// ========== 构造函数 ==========
    constructor() {
        owner = msg.sender;
    }

    /// ========== 功能函数 ==========

    /// @notice 所有者存入 ETH 到宝箱中
    function depositTreasure() public payable onlyOwner {
        require(msg.value > 0, "Must send some ETH");
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice 所有者授权某个用户可以提款，并设定额度
    function approveWithdrawal(address user, uint256 amount) public onlyOwner {
        require(user != address(0), "Invalid user address");

        // 如果该用户第一次授权，则添加进授权列表
        if (allowances[user] == 0 && !hasWithdrawn[user]) {
            authorizedUsers.push(user);
        }

        allowances[user] = amount;
        emit AllowanceSet(user, amount);
    }

    /// @notice 授权用户提取资金（一次性）
    function withdraw() public {
        require(allowances[msg.sender] > 0, "Not approved");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");

        uint256 amount = allowances[msg.sender];
        require(amount <= address(this).balance, "Not enough treasure");

        // 状态更新先于转账，防止重入攻击
        hasWithdrawn[msg.sender] = true;
        allowances[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    /// @notice 所有者可随时提取任意金额
    function ownerWithdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Not enough treasure");
        payable(owner).transfer(amount);
        emit Withdrawal(owner, amount);
    }

    /// @notice 所有者转移控制权并重置所有提款状态
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is zero address");

        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);

        // 重置状态
        for (uint i = 0; i < authorizedUsers.length; i++) {
            hasWithdrawn[authorizedUsers[i]] = false;
        }

        emit WithdrawStatusReset();
    }

    /// @notice 合约接收 ETH（比如外部直接转账）
    receive() external payable {}

    /// @notice 查询当前宝箱余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
