//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{

    //there should be a bank manager who has the certain permissions
    //there should be an array for all members registered and a mapping whther they are registered or not
    //a mapping with there balances
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) balance;

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
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }
    //deposit amount 
    // function depositAmount(uint256 _amount) public onlyRegisteredMember{
    //     require(_amount > 0, "Invalid amount");
    //     balance[msg.sender] = balance[msg.sender]+_amount;
   
    // }
    
    //deposit in Ether
    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] = balance[msg.sender]+msg.value;
   
    }
    
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] = balance[msg.sender]-_amount;
   
    }

    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
}