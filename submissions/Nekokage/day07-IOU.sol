//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;
    
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    
    mapping(address => uint256) public balances;
    
    mapping(address => mapping(address => uint256)) public debts; // debtor -> creditor -> amount
    
    // 取款限制和冷却期
    mapping(address => uint256) public lastWithdrawTime;
    uint256 public cooldownPeriod = 1 days;
    uint256 public maxWithdrawAmount = 2 ether;
    
    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }
    
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");
        
        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }
    
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }
    
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        debts[_debtor][msg.sender] += _amount;
    }
    
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // Update balances and debt
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }
    
    // 添加冷却期检查的直接转账
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // 检查冷却期
        require(
            block.timestamp >= lastWithdrawTime[msg.sender] + cooldownPeriod,
            "Cooldown period not over. Wait before transferring again"
        );
        
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;
        
        // 更新最后转账时间
        lastWithdrawTime[msg.sender] = block.timestamp;
    }
    
    // 添加冷却期检查的call转账
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // 检查冷却期
        require(
            block.timestamp >= lastWithdrawTime[msg.sender] + cooldownPeriod,
            "Cooldown period not over. Wait before transferring again"
        );
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        
        balances[_to] += _amount;
        
        // 更新最后转账时间
        lastWithdrawTime[msg.sender] = block.timestamp;
    }
    
    // 添加取款限制的取现函数
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(_amount <= maxWithdrawAmount, "Amount exceeds maximum withdrawal limit");
        
        // 检查冷却期
        require(
            block.timestamp >= lastWithdrawTime[msg.sender] + cooldownPeriod,
            "Cooldown period not over. Wait before withdrawing again"
        );
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
        
        // 更新最后取款时间
        lastWithdrawTime[msg.sender] = block.timestamp;
    }
    
    // 紧急取款功能（不受限制，但只能由所有者使用）
    function emergencyWithdraw(uint256 _amount) public onlyOwner {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
    
    // 设置取款限制
    function setWithdrawalLimits(uint256 _maxAmount, uint256 _cooldown) public onlyOwner {
        maxWithdrawAmount = _maxAmount;
        cooldownPeriod = _cooldown;
    }
    
    // 重置用户冷却期
    function resetUserCooldown(address _user) public onlyOwner {
        lastWithdrawTime[_user] = 0;
    }
    
    // 查询用户是否可以取款
    function canWithdraw(address _user) public view returns (bool) {
        if (balances[_user] == 0) return false;
        return block.timestamp >= lastWithdrawTime[_user] + cooldownPeriod;
    }
    
    // Check your balance
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
    
    // 获取合约总余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}