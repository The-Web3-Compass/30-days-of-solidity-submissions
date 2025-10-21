//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{

    address public bankManager;////there should be a bank manager who has the certain permissions
    address[] members;//an array for all members registered
    mapping(address => bool) public registeredMembers;//a mapping whther they are registered or not
    mapping(address => uint256) balance;////a mapping with there balances

    constructor(){
        bankManager = msg.sender;
        registeredMembers[msg.sender] = true;//register bankManager
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
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function listMembers() public view returns(address[] memory){
        return members;
    }

    function deposit(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] = balance[msg.sender]+_amount;

    }

    //deposit in Ether
    function depositEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
   
    }
    
    function withdraw(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
   
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 

}