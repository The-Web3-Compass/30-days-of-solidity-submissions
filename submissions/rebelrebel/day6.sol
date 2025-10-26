//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank{
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;

    uint public constant DAILY_WITHDRAWAL_LIMIT = 1 ether;
    mapping(address => uint) public lastWithdrawalTime;
    uint public constant COOLDOWN_PERIOD = 24 hours;

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
  
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    function depositAmountEther() public payable onlyRegisteredMember {  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }
    
    function withdrawEther(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance on the ledger");
        require(_amount <= DAILY_WITHDRAWAL_LIMIT, "Amount exceeds daily withdrawal limit.");
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + COOLDOWN_PERIOD, "Cooldown: You can only withdraw once every 24 hours.");

        balance[msg.sender] -= _amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(_amount);
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
}