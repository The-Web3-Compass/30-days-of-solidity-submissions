// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract IOU {
address public owner;
mapping(address => bool) public ifregister;
address[] public friendlist;
mapping(address => uint256) public balance;
mapping(address => mapping (address=> uint256)) public debt;
constructor(){
 owner = msg.sender;
 ifregister[msg.sender] = true;
 friendlist.push(msg.sender);
}
modifier onlyowner(){
 require(msg.sender == owner, "invalid");
 _;
}
modifier onlyregister(){
 require(ifregister[msg.sender],"invalid");
 _;
}
function addfriend(address _friend) public onlyowner{
 require(_friend != address(0),"invalid");
 require(ifregister[_friend],"invalid");
 ifregister[_friend]=true;
 friendlist.push(_friend);
}
function depositwallet() public payable onlyregister{
 require(msg.value > 0, "invalid");
 balance[msg.sender] += msg.value;
}
function record(address _debtor, uint256 _amount) public onlyregister{
 require(_debtor != address(0), "invalid");
 require(_amount > 0, "invalid");
 require(ifregister[_debtor], "invalid");
 debt[_debtor][msg.sender] = _amount;
}
function pay(address _creditor, uint256 _amount) public onlyregister{
 require(_creditor != address(0), "invalid");
 require(_amount > 0, "invalid");
 require(ifregister[_creditor], "invalid");
 require(debt[msg.sender][_creditor] >= _amount, "invalid");
 require(balance[msg.sender] >= _amount, "invalid");
 balance[msg.sender] -= _amount;
 balance[_creditor] += _amount;
 debt[msg.sender][_creditor] -= _amount;
}
function transfer(address payable _address, uint256 _amount) public onlyregister{
 require(_amount > 0, "invalid");
 require(ifregister[_address], "invalid");
 require(balance[msg.sender] >= _amount, "invalid");
 balance[msg.sender] -= _amount;
 _address.transfer(_amount);
 balance[_address] += _amount;
}
 function withdraw(uint256 _amount) public onlyregister{
 require(balance[msg.sender] >= _amount, "invalid");      
 balance[msg.sender] -= _amount;
 (bool success, ) = payable(msg.sender).call{value: _amount}("");
 require(success, "failed");
}
function check() public view onlyregister returns (uint256) {
  return balance[msg.sender];
}
}