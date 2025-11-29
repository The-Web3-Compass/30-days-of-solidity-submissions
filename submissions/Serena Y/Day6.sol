// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank{

address public bankManager;
address[] members;
mapping(address=>bool) public registeredMembers;
mapping(address=>uint256)balance;

constructor(){
    bankManager=msg.sender;
    members.push(msg.sender);
    registeredMembers[msg.sender] = true;
}

modifier onlyBankManager() {
    require(msg.sender==bankManager,"Only bank manager can perform this action");
    _;
}

modifier onlyRegisteredMembers(){
    require(registeredMembers[msg.sender],"Member not registered");
    _;
}
//添加成员
function addMembers(address _member) public onlyBankManager{
    require(_member !=address(0),"Invalid address");//添加成员地址不能为空
    require(_member != msg.sender,"Bank Manager is already a member");//添加成员不能是银行经理
    require(!registeredMembers[_member],"Member already registered");//添加成员不能是已经注册的成员
    registeredMembers[_member]=true;//将成员登记
    members.push(_member);//把成员写进会员中
}
//获得成员信息
function getMembers() public view returns(address[] memory){
    return members;
}
//配置以太坊
function depositAmountEther() public payable onlyRegisteredMembers{
    require(msg.value>0,"Invalid amount");//存入金额不能为0
    balance[msg.sender]+=msg.value;//剩余存款=存入金额+之前的存款
}
//取钱函数
function withdrawAmount(uint _amount) public onlyRegisteredMembers{
    require(_amount>0,"Invalid amount");//取钱金额不能为0
    require(balance[msg.sender]>=_amount,"Insufficient balance");//取钱金额不能多于存款
    balance[msg.sender]-=_amount;//剩余存款=之前的存款-取款金额
}
function getBalance(address _member) public view returns (uint256){
    require(_member!=address(0),"Invalid address");
    return balance[_member];
}

}
