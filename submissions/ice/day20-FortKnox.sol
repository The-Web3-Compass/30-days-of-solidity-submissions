// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title FortKnox
 * @dev 安全的数字保险库
 * 功能点：
 * 1. 用户可以在其中存入和提取代币
 * 2. 确保其免受重入攻击：防止攻击者在余额更新之前反复触发提现逻辑。
 * 3. 实施 'nonReentrant' 修饰符来阻止重新进入尝试
 * 重入攻击防护，安全提款 nonReentrant modifier/Reentrancy attacks 
 */
contract FortKnox {
    // 用户余额映射
    mapping(address => uint256) private balances;
    
    // 合约所有者
    address public owner;
    
    // 重入锁状态
    uint256 private _status;
    
    // 锁定状态常量
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    
    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
    /**
     * @dev 构造函数
     */
    constructor() {
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }
    
    /**
     * @dev 修饰符：防止重入攻击
     */
    modifier nonReentrant() {
        // 检查当前状态
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        
        // 设置状态为已进入
        _status = _ENTERED;
        
        // 执行函数
        _;
        
        // 恢复状态
        _status = _NOT_ENTERED;
    }
    
    /**
     * @dev 修饰符：仅合约所有者可调用
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev 存款函数
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新用户余额
        balances[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev 提款函数 - 使用重入防护
     * @param _amount 提款金额
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // 重要：先减少余额，再发送ETH
        balances[msg.sender] -= _amount;
        
        // 发送ETH到用户地址
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, _amount);
    }
    
    /**
     * @dev 查询用户余额
     * @param _user 用户地址
     * @return 用户余额
     */
    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    /**
     * @dev 紧急提款 - 仅合约所有者可调用
     * @param _amount 提款金额
     */
    function emergencyWithdraw(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount <= address(this).balance, "Insufficient contract balance");
        
        // 发送ETH到所有者地址
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit EmergencyWithdrawal(owner, _amount);
    }
    
    /**
     * @dev 获取合约余额
     * @return 合约余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @title AttackerContract
 * @dev 用于演示重入攻击的合约
 */
contract AttackerContract {
    // 目标FortKnox合约
    FortKnox public target;
    
    // 攻击者地址
    address public attacker;
    
    // 攻击状态
    bool public attacking = false;
    
    // 事件
    event AttackStarted(address indexed target, uint256 amount);
    event AttackCompleted(address indexed target, uint256 stolenAmount);
    
    /**
     * @dev 构造函数
     * @param _target 目标FortKnox合约地址
     */
    constructor(address payable _target) {
        target = FortKnox(_target);
        attacker = msg.sender;
    }
    
    /**
     * @dev 开始攻击
     */
    function attack() external payable {
        require(msg.sender == attacker, "Only attacker can call this function");
        require(msg.value > 0, "Need ETH to start attack");
        
        // 首先存入一些ETH到目标合约
        target.deposit{value: msg.value}();
        
        // 开始攻击
        attacking = true;
        
        emit AttackStarted(address(target), msg.value);
        
        // 尝试提取资金并触发重入攻击
        target.withdraw(msg.value);
        
        // 攻击完成
        attacking = false;
        
        // 将所有ETH发送给攻击者
        uint256 stolenAmount = address(this).balance;
        if (stolenAmount > 0) {
            payable(attacker).transfer(stolenAmount);
            emit AttackCompleted(address(target), stolenAmount);
        }
    }
    
    /**
     * @dev 回退函数 - 用于执行重入攻击
     * 如果FortKnox合约没有重入保护，这个函数会被反复调用
     */
    receive() external payable {
        if (attacking && address(target).balance >= 1 ether) {
            // 尝试再次提取资金
            target.withdraw(1 ether);
        }
    }
}

