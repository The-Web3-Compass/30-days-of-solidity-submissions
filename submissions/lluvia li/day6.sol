// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

contract PiggyBank{
   
   address public BankManager;
   address[] members;
   mapping (address=>bool) public registermembers;
   mapping (address=>uint256) balance;

   constructor(){
    BankManager=msg.sender;
    members.push(msg.sender);
   }

   modifier OnlyBankManager(){
    require(msg.sender==BankManager,"Only bank manager can perform this action");

    _;
   }
  
  modifier OnlyRegisterMember(){
    require(registermembers[msg.sender],"Member not registered");
    _;

  }

  function addMembers(address _member) public OnlyBankManager{
    require(_member != address(0),"Invalid ");
    require(_member != msg.sender,"Bank Manager is already a member");
    require(!registermembers[_member],"Member already registered");

    registermembers[_member]=true;
    members.push(_member);
  }

  function getMembers() public view returns(address[] memory){
    return members;
  }
  
  function deposit(uint256 _amount) public OnlyRegisterMember{
    require(_amount>0,"Invalid amount");
    balance[msg.sender]+=_amount;

  }

   function depositEther() public payable OnlyRegisterMember{
    require(msg.value>0,"Invalid amount");
    balance[msg.sender]+= msg.value;

  }

  function getbalance(address _member) public view returns(uint256){
    require( _member!= address(0),"Invalid address");
    return balance[_member];
  }

  function withdrawal(uint256 _amount) public OnlyRegisterMember{
    require(_amount>=0, "Invalid amount");
    require(_amount<= balance[msg.sender],"Insuffient banlance");
    balance[msg.sender]-=_amount;
    
  }



}
