//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank{

    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;
    
    //取款限制变量
    mapping(address => uint256) public lastWithdrawTime; // 最后取款时间
    uint256 public cooldownPeriod = 1 days; // 冷却期：1天
    uint256 public maxWithdrawAmount = 1 ether; // 单次最大取款：1 ETH

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true; // 银行经理自动注册
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }
  
    function addMembers(address _member) public onlyBankManager{
        require(_member != address(0), "Invalid address");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }
    
    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] = balance[msg.sender] + msg.value;
    }
    
    // 原有的内部余额减少函数
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] = balance[msg.sender] - _amount;
    }
    
    // 实际取现函数 - 将以太币发送给用户
    function withdrawEther(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Amount must be greater than 0");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        require(_amount <= maxWithdrawAmount, "Exceeds maximum withdrawal amount");
        
        // 检查冷却期
        require(
            block.timestamp >= lastWithdrawTime[msg.sender] + cooldownPeriod,
            "Cooldown period not over"
        );
        
        // 更新内部余额
        balance[msg.sender] = balance[msg.sender] - _amount;
        
        // 实际发送以太币
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        // 更新最后取款时间
        lastWithdrawTime[msg.sender] = block.timestamp;
    }
    
    // 银行经理可以调整取款限制
    function setWithdrawLimit(uint256 _maxAmount, uint256 _cooldown) public onlyBankManager {
        maxWithdrawAmount = _maxAmount;
        cooldownPeriod = _cooldown;
    }
    
    // 银行经理可以重置用户的冷却期
    function resetUserCooldown(address _user) public onlyBankManager {
        lastWithdrawTime[_user] = 0;
    }
    
    //查询用户是否可以取款
    function canWithdraw(address _user) public view returns (bool) {
        if (balance[_user] == 0) return false;
        return block.timestamp >= lastWithdrawTime[_user] + cooldownPeriod;
    }
    
    // 查询用户还需要等待多久才能取款
    function timeUntilWithdraw(address _user) public view returns (uint256) {
        if (block.timestamp >= lastWithdrawTime[_user] + cooldownPeriod) {
            return 0;
        }
        return (lastWithdrawTime[_user] + cooldownPeriod) - block.timestamp;
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    }
    
    // 获取合约总余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}