// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner; // 所有者
    uint256 public treasureAmount; // 宝箱
    mapping(address => uint256) public withdrawalAllowance; //映射每个地址提取多少
    mapping(address => bool) public hasWithdrawn; //映射地址是否已提款
    // 设置所有者
    constructor(){
        owner = msg.sender;
    }
    // 修饰符重置访问控制权
    modifier onlyOwner(){
        require(msg.sender == owner, "Access denied: Only the the owner can perform this action");
        _;
    }
    // 将宝藏添加到宝箱内  仅所有者可操作
    function addTreasureAmount(uint256 _amount) public onlyOwner{
        treasureAmount += _amount;
    }
    // 批准他人提款 仅所有者可操作 (每个地址允许取多少)
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner{
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }
    // 实际提款 1. 业主提款 2.普通用户提款
    function withdrawTreasure(uint256 amount) public {
        //业主提款
        if(msg.sender == owner){
            require(amount <= treasureAmount, "Not enough treasury available for this action");
            treasureAmount -= amount;
            return;
        }
        // 普通用户提款
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");

        hasWithdrawn[msg.sender] = true; // 标记
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0; // 重置即无法重试
    }
    // 重置用户提款状态
    function resetWithdrawalStatus(address user) public onlyOwner{
        hasWithdrawn[user] = false;
    }
    // 转让所有者权限
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0),"Invalid address");
        owner = newOwner;
    }
    // 查看宝藏
    function getTreasureDetails() public view onlyOwner returns(uint256){
        return treasureAmount;
    }
}