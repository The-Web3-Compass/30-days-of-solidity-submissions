// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

contract TheEtherPiggyBank {
    address public bankManager;
    address[] members;
    mapping(address=>bool) public registeredMembers;
    mapping(address=>uint256) balance;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }
    // 设置管理员权限
    modifier onlyBankManager(){
        require(msg.sender==bankManager, "Only bank manager can perform this action");
        _;
    }
    // 设置注册会员权限
    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender],"Member not registered");
        _;
    }
    // 添加新成员
    function addMembers(address _member) public onlyBankManager{
        require(_member!=address(0),"Invalid address");
        require(_member!=msg.sender,"Bank Manager is already a member");
        require(!registeredMembers[_member],"Member already registered");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    // 查看成员
    function getMembers() public view returns (address[] memory){
        return members;
    }

    //存储
    function deposit(uint256 _amount) public onlyRegisteredMember{
        require(_amount>0,"Invalid amount");
        balance[msg.sender] += _amount;
    }

    // 提取
    function withdraw(uint256 _amount) public onlyRegisteredMember{
        require(_amount>0,"Invalid amount");
        require( balance[msg.sender] >= _amount,"Insufficient balance");
        balance[msg.sender] -= _amount;
    }

    // 将以太币存储
    function depositAmountEther() public payable onlyRegisteredMember{
        require(msg.value>0,"Invalid amount");
        balance[msg.sender] += msg.value;
    }
}