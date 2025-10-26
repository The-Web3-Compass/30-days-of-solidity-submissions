// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank {

    address public bankManager;  
    address[] members;    
    mapping(address => bool) public registeredMembers;  
    mapping(address => uint256) balance;  // 映射

    constructor() {
        bankManager = msg.sender;  
        members.push(msg.sender);  
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;  // 执行限制
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;  // 执行限制
    }

    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");  // 确保地址有效
        require(_member != msg.sender, "Bank Manager is already a member");  
        require(!registeredMembers[_member], "Member already registered");  
        registeredMembers[_member] = true;  
        members.push(_member);  
    }

    function getMembers() public view returns(address[] memory) {
        return members; 
    }

    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Invalid amount");  
        balance[msg.sender] = balance[msg.sender] + msg.value; 
    }

    function withdrawAmount(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Invalid amount");  // 确保提现金额大于0
        require(balance[msg.sender] >= _amount, "Insufficient balance");  // 确保余额足够
        balance[msg.sender] = balance[msg.sender] - _amount;  // 扣除余额
    }

    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");  
        return balance[_member];  // 获取余额
    }
}
