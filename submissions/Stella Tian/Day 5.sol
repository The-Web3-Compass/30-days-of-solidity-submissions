// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract admin{
 address public owner;
 uint256 public treasure;
 mapping(address => uint256) public withdrawaltreasure;
 uint256 public allowence = withdrawaltreasure[msg.sender];
 mapping(address => bool) public ifwithdrawal;
 mapping(address => uint256) public lastwithdraw;
 uint256 public maxwithdrawal;
 uint256 public cooltime;
 constructor() {
    owner = msg.sender;
 }
 modifier onlyowner() {
    require(msg.sender == owner, "you are not the owner");
    _;
 }
 
 function addtreasure(uint256 amount) public onlyowner {
 treasure += amount;
 }
 function addmaxwithdrawal(uint256 _maxwithdrawal) public onlyowner{
 maxwithdrawal = _maxwithdrawal;
 }
 function addcooltime(uint256 _cooltime) public onlyowner{
 cooltime = _cooltime*1 hours;
 }
 function approvewithdraw(address recipient, uint256 amount) public onlyowner{
  require(amount <= treasure, "can't withdraw more than the owner amount");
  withdrawaltreasure[recipient] = amount;
 }
 function ifapprove() public view returns(bool) {
  return withdrawaltreasure[msg.sender]>0;
 }
 function withdraw(uint256 amount) public{
  if (msg.sender == owner){
   require(amount <= treasure, "amount greater than the owner amount");
   require(amount <= maxwithdrawal, "amount greater than the max limited");
   require(block.timestamp >= lastwithdraw[msg.sender]+cooltime);
   treasure -= amount;
   return;
  }
  require(allowence>0,"you dont have any allowence");
  require(!ifwithdrawal[msg.sender], "you had already withdrawn");
  require(allowence <= treasure, "amount greater than the owner amount");
  require(allowence <= maxwithdrawal, "amount greater than the max limited");
  require(block.timestamp >= lastwithdraw[msg.sender]+cooltime,"not valid");
  ifwithdrawal[msg.sender] = true;
  treasure -= allowence;
  withdrawaltreasure[msg.sender] = 0;
 }
 function viewstate() public view returns(bool){
  return ifwithdrawal[msg.sender];
 }
 function reset(address user) public onlyowner{
  ifwithdrawal[user] = false;
 }
 function detail() public view onlyowner returns(uint256){
    return treasure;
 }
 function ownership(address newowner) public onlyowner{
    require(newowner != address(0), "invaid address");
    owner =newowner;
 }
}