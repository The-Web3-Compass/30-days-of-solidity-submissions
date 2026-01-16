// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
  address public bankManager;

  address [] members;
  mapping(address => bool) registeredMembers;

  mapping(address => uint256) balance;

  contructor() {
    bankManager = msg.sender;
    members.push(bankManager);
  }

  modifier onluBankManager() {
    require(msg.sender == bankManager, "You don't have the permission.");
    _;
  }

   
  modifier onlyRegisteredMember() {
      require(registeredMembers[msg.sender], "Member not registered");
      _;
}

   
function addMembers(address _member) public onlyBankManager {
    require(_member != address(0), "Invalid address");
    require(_member != msg.sender, "Bank Manager is already a member");
    require(!registeredMembers[_member], "Member already registered");

    registeredMembers[_member] = true;
    members.push(_member);
}

 
function getMembers() public view returns (address[] memory) {
    return members;
}

 
function deposit(uint256 _amount) public onlyRegisteredMember {
    require(_amount > 0, "Invalid amount");
    balance[msg.sender] += _amount;
}

 
function withdraw(uint256 _amount) public onlyRegisteredMember {
    require(_amount > 0, "Invalid amount");
    require(balance[msg.sender] >= _amount, "Insufficient balance");
    balance[msg.sender] -= _amount;
}

 
function depositAmountEther() public payable onlyRegisteredMember {
    require(msg.value > 0, "Invalid amount");
    balance[msg.sender] += msg.value;
}




}
