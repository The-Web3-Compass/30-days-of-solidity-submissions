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

}