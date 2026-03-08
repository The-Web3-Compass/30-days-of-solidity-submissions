// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EtherPiggyBank {

    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;

    
    mapping(address => uint256) public lastWithdrawTime; 
    mapping(address => bool) public withdrawalApproved; 
    uint256 public maxWithdrawLimit = 0.5 ether; 
    uint256 public cooldownTime = 1 days; 

    constructor(){
        bankManager = msg.sender;
        registeredMembers[msg.sender] = true; 
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

 
    function approveMemberWithdrawal(address _member, bool _status) public onlyBankManager {
        withdrawalApproved[_member] = _status;
    }
  
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function depositAmount() public payable onlyRegisteredMember {  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }
    
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember {
        
        require(_amount <= maxWithdrawLimit, "Amount exceeds withdrawal limit");

        
        if(msg.sender != bankManager) {
            require(block.timestamp >= lastWithdrawTime[msg.sender] + cooldownTime, "Cooldown active: Try again later");
            
            require(withdrawalApproved[msg.sender], "Withdrawal not approved by manager");
        }

        require(balance[msg.sender] >= _amount, "Insufficient balance");

        
        balance[msg.sender] -= _amount;
        lastWithdrawTime[msg.sender] = block.timestamp;
        
        
        if(balance[msg.sender] == 0) withdrawalApproved[msg.sender] = false;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function getMembers() public view onlyBankManager returns(address[] memory) {
        return members;
    }

    function getBalance(address _member) public view returns (uint256){
        return balance[_member];
    } 
}
