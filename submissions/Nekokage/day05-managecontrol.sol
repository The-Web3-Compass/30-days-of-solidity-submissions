// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleAdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    
    // 记录每个用户最后一次提款时间
    mapping(address => uint256) public lastWithdrawalTime;
    
    event Withdrawal(address user, uint256 amount);
    event ApprovalGranted(address user, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    // 只有owner能调用的修饰器
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this");
        _;
    }
    
    // 添加资金
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }
    
    // 批准用户提款
    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure");
        withdrawalAllowance[recipient] = amount;
        hasWithdrawn[recipient] = false; // 重置提款状态
        lastWithdrawalTime[recipient] = 0; // 重置冷却时间
        
        emit ApprovalGranted(recipient, amount);
    }
    
    // 修复后的提款函数
    function withdrawTreasure(uint256 amount) public {
        require(amount > 0, "Amount must be positive");
        require(amount <= treasureAmount, "Not enough treasure");
        
        if(msg.sender == owner){
            // 所有者可以随时提取
            treasureAmount -= amount;
            return;
        }
        
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance >= amount, "Cannot withdraw more than allowance");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        
        // 检查冷却时间：至少等待1分钟才能再次提款
        require(
            block.timestamp >= lastWithdrawalTime[msg.sender] + 1 minutes,
            "Wait 1 minute between withdrawals"
        );
        
        // 执行提款
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] -= amount; // 减少剩余额度
        
        // 更新最后提款时间
        lastWithdrawalTime[msg.sender] = block.timestamp;
        
        // 如果额度用完，标记为已提款
        if(withdrawalAllowance[msg.sender] == 0) {
            hasWithdrawn[msg.sender] = true;
        }
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // 简单的查询函数
    function canIWithdraw() public view returns (bool, uint256) {
        if(msg.sender == owner) {
            return (true, treasureAmount);
        }
        
        bool canWithdraw = withdrawalAllowance[msg.sender] > 0 && 
                          !hasWithdrawn[msg.sender] &&
                          block.timestamp >= lastWithdrawalTime[msg.sender] + 1 minutes;
        
        return (canWithdraw, withdrawalAllowance[msg.sender]);
    }
    
    // 重置用户状态
    function resetUser(address user) public onlyOwner {
        hasWithdrawn[user] = false;
        lastWithdrawalTime[user] = 0;
    }
    
    // 转移所有权
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}