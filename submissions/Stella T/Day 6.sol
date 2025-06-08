// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract bank{
 address public banker;
 address[] member;
 address[] application;
 mapping(address => bool) public ifmember;
 mapping(address => bool) public ifapplication;
 mapping(address => uint) balance;
 constructor(){
  banker = msg.sender;
  member.push(msg.sender);
 }
 modifier onlybanker() {
  require(banker==msg.sender, "only banker can modify");
  _;
 }
 modifier onlymember() {
  require(ifmember[msg.sender], "only member have permission");
  _;
 }
 function register(address _application) public{
 require(_application != address(0), "inlalid");
 require(_application ==msg.sender,"already a member");
 require(!ifmember[_application],"already a member");
 application.push(_application);
 ifapplication[msg.sender]= true;
 }
 function approve(address _application) public onlybanker{
 require(_application != address(0),"invalid");
  require(_application ==msg.sender, "already a member");
  require(!ifmember[_application],"already a member");
  require(ifapplication[_application], "not in the list");
  ifmember[_application]=true;
  member.push(_application);
 }
 function viewapprove() public view returns(bool){
 return ifmember[msg.sender];
 }
 function addmember(address _member) public onlybanker{
  require(_member != address(0),"invalid");
  require(!ifmember[_member],"already a member");
  ifmember[_member]=true;
  member.push(_member);
 }
 function getmember() view public returns(address[] memory){
  return member;
 }
 function deposit() public payable onlymember{
 require(msg.value > 0, "invaid");
 balance[msg.sender] += msg.value;
 }
}