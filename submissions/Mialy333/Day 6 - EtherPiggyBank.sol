//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

contract EtherPiggyBank{

  address public bankManager;
  address[] members;
  mapping(address => bool) public registeredMembers;
  mapping(address => uint256) balance;

  constructor(){
    bankManager = msg.sender;
    members.push(msg.sender);
  
  }

  modifier onlyBankManager(){
    require(bankManager == msg.sender, "Only bank manager can perform this action");
    _;
  }

  modifier onlyRegisteredMember(){
    require(registeredMembers[msg.sender], "Member is not registered");
    _;
  }

  function addMembers(address _member) public onlyBankManager{
    require(_member != address(0), "Invalid address");
    require(_member != msg.sender, "Bank Manager is already a member");
    require(!registeredMembers[_member], "Member is already registered");
    registeredMembers[_member] = true; 
    members.push(_member);
  }
}