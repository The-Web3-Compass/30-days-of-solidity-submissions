//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{

    //there should be a bank manager who has the certain permissions
    //there should be an array for all members registered and a mapping whther they are registered or not
    //a mapping with there balances
    address public bankManager;
    address[] members;
    mapping(address => bool) public registeredMembers; //检查注册成员
    mapping(address => uint256) balance; //余额

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender); //将银行经理加入到注册成员列表中
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
        require(_member != address(0), "Invalid address");                  //确保地址有效
        require(_member != msg.sender, "Bank Manager is already a member"); 
        require(!registeredMembers[_member], "Member already registered");  //检查是否已经注册
        registeredMembers[_member] = true;
        members.push(_member);                                              //新成员注册=添加新成员地址到成员列表数组中
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    //deposit amount 存入“虚拟币”，测试系统逻辑
    function depositAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
         balance[msg.sender] += _amount;
   
     }
    
    //deposit in Ether 将真正的以太币存入储蓄罐
    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
   
    }
    
    //取钱（模拟）
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
   
    }

    // 查看余额
    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
}


//0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
//0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db