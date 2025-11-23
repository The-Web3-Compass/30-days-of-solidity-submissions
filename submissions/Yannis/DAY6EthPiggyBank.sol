//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{

    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;
    mapping(address => bool) public approvedWithdrawals;      
    uint256 public cooldownSeconds;                           
    mapping(address => uint256) public lastWithdrawTime;      
    uint256 public maxWithdrawPerTx = type(uint256).max;      
    mapping(address => uint256) public userMaxWithdraw;      

    
    event MemberAdded(address indexed member);
    event Deposited(address indexed member, uint256 amount);
    event Withdrawn(address indexed member, uint256 amount);
    event WithdrawalApproved(address indexed member, bool approved);
    event CooldownSet(uint256 seconds_);
    event MaxWithdrawPerTxSet(uint256 amount);
    event UserMaxWithdrawSet(address indexed user, uint256 amount);

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true; 
        emit MemberAdded(msg.sender);
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
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
        emit MemberAdded(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }
    //deposit amount 
    // function depositAmount(uint256 _amount) public onlyRegisteredMember{
    //     require(_amount > 0, "Invalid amount");
    //     balance[msg.sender] = balance[msg.sender]+_amount;
   
    // }
    
    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] = balance[msg.sender]+msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");

        if (msg.sender != bankManager) {
            require(approvedWithdrawals[msg.sender], "Withdrawal not approved");
        }

        require(lastWithdrawTime[msg.sender] == 0 || block.timestamp >= lastWithdrawTime[msg.sender] + cooldownSeconds,
            "Cooldown active, try later");

        uint256 allowedLimit = userMaxWithdraw[msg.sender] > 0 ? userMaxWithdraw[msg.sender] : maxWithdrawPerTx;
        require(_amount <= allowedLimit, "Exceeds per-tx withdraw limit");

        balance[msg.sender] = balance[msg.sender]-_amount;
        lastWithdrawTime[msg.sender] = block.timestamp;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Withdraw transfer failed");

        emit Withdrawn(msg.sender, _amount);
    }

    function approveWithdrawal(address user, bool approved) public onlyBankManager {
        approvedWithdrawals[user] = approved;
        emit WithdrawalApproved(user, approved);
    }

    function setCooldownSeconds(uint256 seconds_) public onlyBankManager {
        cooldownSeconds = seconds_;
        emit CooldownSet(seconds_);
    }

    function setMaxWithdrawPerTx(uint256 amount) public onlyBankManager {
        maxWithdrawPerTx = amount;
        emit MaxWithdrawPerTxSet(amount);
    }

    function setUserMaxWithdraw(address user, uint256 amount) public onlyBankManager {
        userMaxWithdraw[user] = amount;
        emit UserMaxWithdrawSet(user, amount);
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
}
