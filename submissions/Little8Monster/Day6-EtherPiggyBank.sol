// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//以太币储蓄罐智能合约
contract EtherPiggyBank{
    address public bankManager;
    address[] members;//数组for all members
    mapping (address => bool) public registeredMembers;
    mapping (address => uint256) balance;

constructor(){
    bankManager = msg.sender;
    members.push(msg.sender);
}
//部署的人既是银行经理，也是第一个成员
//.push 就是把 msg.sender 也推进 members 数组里

modifier onlyBankManager(){
    require(msg.sender == bankManager, "Only bank manager can perform this action");
    _;
}

modifier onlyRegisteredMember(){
    require(registeredMembers[msg.sender], "Member not registered");
    _;
}

//增加成员
function addMembers(address _member)public onlyBankManager{
    require(_member != address(0), "Invalid address");
    require(_member != msg.sender, "Bank Manager is already a member");
    require(!registeredMembers[_member], "Member already register");
    registeredMembers[_member] = true;
    members.push(_member);
}

//查看成员
function getMembers() public view returns(address[] memory){
    return members;
}

//存款（模拟储蓄）deposit amount
// function depositAmount(uint256 _amount) public onlyRegisteredMember{
    // require(_amount > 0, "Invalid amount");
    // balance[msg.sender] = balance[msg.sender]+_amount;
//}

//将真正的以太币存入储蓄罐deposit in Ether
function depositAmountEther() public payable onlyRegisteredMember{
    require(msg.value > 0, "Invalid amount");
    balance[msg.sender] = balance[msg.sender]+msg.value;
}
//payable 表示该函数可以接收以太币。没有它，别人发来的以太币都会被拒收。
//msg.value 表示用户在交易中发送的以太币数量（单位是 wei ，以太币最小的计量单位）
//以太币会被存储到合约内部，并同时被记入成员的余额


//取钱
function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
    require(_amount > 0, "Invalid amount");
    require(balance[msg.sender] >= _amount, "Insufficient balance");
    balance[msg.sender] = balance[msg.sender]-_amount;
}

//查账本余额
function getBalance(address _member) public view returns (uint256){
    require(_member != address(0), "Invalid address");
    return balance[_member];
}
}