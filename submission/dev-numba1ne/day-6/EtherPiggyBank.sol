//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    // State variables
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;
    
    // New variables for limits and cooldowns
    uint256 public dailyWithdrawalLimit;
    uint256 public minimumDepositAmount;
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public dailyWithdrawnAmount;
    mapping(address => bool) public withdrawalRequests;
    uint256 public withdrawalCooldown;
    
    // Events
    event MemberAdded(address indexed member);
    event EtherDeposited(address indexed member, uint256 amount);
    event WithdrawalRequested(address indexed member, uint256 amount);
    event WithdrawalApproved(address indexed member, uint256 amount);
    event WithdrawalExecuted(address indexed member, uint256 amount);
    event LimitsUpdated(uint256 withdrawalLimit, uint256 minimumDeposit, uint256 cooldown);
    
    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
        
        // Initialize limits and cooldowns
        dailyWithdrawalLimit = 1 ether;
        minimumDepositAmount = 0.01 ether;
        withdrawalCooldown = 1 days;
    }
    
    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }
    
    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }
    
    // Reset daily withdrawal amount if a new day has started
    modifier resetDailyWithdrawal() {
        if (block.timestamp >= lastWithdrawalTime[msg.sender] + 1 days) {
            dailyWithdrawnAmount[msg.sender] = 0;
        }
        _;
    }
    
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
        emit MemberAdded(_member);
    }
    
    function getMembers() public view returns(address[] memory) {
        return members;
    }
    
    function depositAmountEther() public payable onlyRegisteredMember {  
        require(msg.value >= minimumDepositAmount, "Deposit amount below minimum");
        balance[msg.sender] += msg.value;
        emit EtherDeposited(msg.sender, msg.value);
    }
    
    // Request a withdrawal (for amounts exceeding half the daily limit)
    function requestWithdrawal(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        require(_amount > dailyWithdrawalLimit / 2, "Use direct withdrawal for smaller amounts");
        require(!withdrawalRequests[msg.sender], "Withdrawal already requested");
        
        withdrawalRequests[msg.sender] = true;
        emit WithdrawalRequested(msg.sender, _amount);
    }
    
    // Bank manager approves withdrawal request
    function approveWithdrawal(address _member) public onlyBankManager {
        require(withdrawalRequests[_member], "No pending withdrawal request");
        withdrawalRequests[_member] = false;
        emit WithdrawalApproved(_member, 0);
    }
    
    // Direct withdrawal without approval (with limits)
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember resetDailyWithdrawal {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        
        // Check if amount is within daily limit
        require(dailyWithdrawnAmount[msg.sender] + _amount <= dailyWithdrawalLimit, 
                "Amount exceeds daily withdrawal limit");
        
        // Check cooldown for repeated withdrawals
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + withdrawalCooldown || 
                lastWithdrawalTime[msg.sender] == 0,
                "Withdrawal cooldown period not passed");
        
        // Update state before transfer to prevent reentrancy
        uint256 amountToWithdraw = _amount;
        balance[msg.sender] -= amountToWithdraw;
        dailyWithdrawnAmount[msg.sender] += amountToWithdraw;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        
        // Transfer Ether to the user
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Transfer failed");
        
        emit WithdrawalExecuted(msg.sender, amountToWithdraw);
    }
    
    // Withdrawal after approval (no daily limit applied)
    function withdrawApprovedAmount(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        require(!withdrawalRequests[msg.sender], "Withdrawal request still pending");
        
        // Check cooldown for repeated withdrawals
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + withdrawalCooldown || 
                lastWithdrawalTime[msg.sender] == 0,
                "Withdrawal cooldown period not passed");
        
        // Update state before transfer to prevent reentrancy
        uint256 amountToWithdraw = _amount;
        balance[msg.sender] -= amountToWithdraw;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        
        // Transfer Ether to the user
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Transfer failed");
        
        emit WithdrawalExecuted(msg.sender, amountToWithdraw);
    }
    
    // Update limits and cooldowns
    function updateLimits(uint256 _dailyLimit, uint256 _minDeposit, uint256 _cooldown) public onlyBankManager {
        dailyWithdrawalLimit = _dailyLimit;
        minimumDepositAmount = _minDeposit;
        withdrawalCooldown = _cooldown;
        emit LimitsUpdated(_dailyLimit, _minDeposit, _cooldown);
    }
    
    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");
        return balance[_member];
    }
    
    // Get contract balance (only bank manager)
    function getContractBalance() public view onlyBankManager returns (uint256) {
        return address(this).balance;
    }
}
