// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GoldVault {
    mapping(address => uint256) public goldBalance;
    
    // 重入锁状态
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event AttackAttempt(address indexed attacker, string reason);
    
    constructor() {
        _status = _NOT_ENTERED;
    }
    
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    
    // 存款函数
    function deposit() external payable {
        require(msg.value > 0, "Must deposit something");
        goldBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // 易受攻击的提取函数
    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        // 危险：先转账，后更新状态
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        goldBalance[msg.sender] = 0;  // 状态更新在转账之后！
        emit Withdrawal(msg.sender, amount);
    }
    
    // 安全的提取函数 (检查-效果-交互模式)
    function safeWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        // 安全：先更新状态
        goldBalance[msg.sender] = 0;
        
        // 后进行外部调用
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // 使用重入锁的提取函数
    function guardedWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        goldBalance[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // 获取合约余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // 获取用户余额
    function getUserBalance(address user) external view returns (uint256) {
        return goldBalance[user];
    }
}