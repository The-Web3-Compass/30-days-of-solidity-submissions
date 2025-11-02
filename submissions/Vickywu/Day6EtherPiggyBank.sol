//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{

    //there should be a bank manager who has the certain permissions
    //there should be an array for all members registered and a mapping w hther they are registered or not
    //a mapping with there balances
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;   //快速检查某人是否已被批准
    mapping(address => uint256) balance;  //每个人存了多少钱

    // 新增：冷却期和审批机制
    mapping(address => uint256) private lastWithdrawalTime;  // 记录上次提款时间
    mapping(address => bool) private withdrawalApproved;     // 管理员审批状态
    uint256 public constant COOLDOWN_PERIOD = 7 days;         // 冷却期：7天
    uint256 public dailyWithdrawalLimit = 1 ether;            // 每日提款限额（可由管理员调整）

    // 事件
    event EtherWithdrawn(address indexed member, uint256 amount);
    event WithdrawalApproved(address indexed member, bool approved);
    event DailyLimitUpdated(uint256 newLimit);

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }
  
    function addMembers(address _member)public onlyBankManager{
        require(_member != address(0), "Invalid address");   //地址是否有效
        require(_member != msg.sender, "Bank Manager is already a member");   //经理没有重复添加自己
        require(!registeredMembers[_member], "Member already registered");    //该成员是否已经存在
        registeredMembers[_member] = true;
        members.push(_member);
    }

    //查看成员列表
    function getMembers() public view returns(address[] memory){
        return members;
    }

    //模拟储蓄
    function deposit(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] += _amount;
    }


    //deposit in Ether
    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");    //确保存入金额大于零
        balance[msg.sender] = balance[msg.sender]+msg.value;   //将该金额加到余额中
   
    }
    
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");  //金额是否有效
        require(balance[msg.sender] >= _amount, "Insufficient balance");  //余额是否足够
        balance[msg.sender] = balance[msg.sender]-_amount;  //把取的钱从余额中扣掉
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    }

    // 管理员设置用户提款审批状态
    function setWithdrawalApproval(address _member, bool _approved) public onlyBankManager {
        require(registeredMembers[_member], "Member not registered");
        withdrawalApproved[_member] = _approved;
        emit WithdrawalApproved(_member, _approved);
    }

    // 管理员更新每日提款限额
    function updateDailyLimit(uint256 _newLimit) public onlyBankManager {
        dailyWithdrawalLimit = _newLimit;
        emit DailyLimitUpdated(_newLimit);
    }

    // 提现ETH（带冷却期+限额+审批检查）
    function withdrawEther(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        require(withdrawalApproved[msg.sender], "Withdrawal not approved by manager");

        // 检查冷却期
        require(
            block.timestamp >= lastWithdrawalTime[msg.sender] + COOLDOWN_PERIOD,
            "Cooldown period not elapsed"
        );

        // 检查每日限额（简单实现：基于最后一次提款的自然日）
        uint256 lastWithdrawalDay = (lastWithdrawalTime[msg.sender] / 1 days) * 1 days;
        uint256 currentDay = (block.timestamp / 1 days) * 1 days;
        if (currentDay == lastWithdrawalDay) {
            require(_amount <= dailyWithdrawalLimit, "Daily limit exceeded");
        }

        // 更新状态并转账
        balance[msg.sender] -= _amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(_amount);
        emit EtherWithdrawn(msg.sender, _amount);
    }

    // 查询用户的提款状态
    function getWithdrawalStatus(address _member) public view returns (
        bool isApproved,
        uint256 lastWithdrawal,
        uint256 cooldownRemaining,
        uint256 dailyLimit
    ) {
        require(registeredMembers[_member], "Member not registered");
        uint256 remaining = lastWithdrawalTime[_member] + COOLDOWN_PERIOD > block.timestamp
            ? lastWithdrawalTime[_member] + COOLDOWN_PERIOD - block.timestamp
            : 0;
        return (
            withdrawalApproved[_member],
            lastWithdrawalTime[_member],
            remaining,
            dailyWithdrawalLimit
        );
    }

    // 防止意外ETH转账
    receive() external payable {
        revert("Use depositAmountEther instead");
    } 


}