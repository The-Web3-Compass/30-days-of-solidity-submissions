// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank{
    address public bankManager;
    address[] members;
    mapping(address => bool) public registerMembers;
    mapping(address => uint256) public balance;
    
    constructor (){
        bankManager = msg.sender;
        members.push(msg.sender);
        registerMembers[msg.sender] = true;
    }

    modifier  onlyBankManager(){
        require(msg.sender == bankManager,"you are not bankManger");
        _;
    }

    modifier  onlyRegisterMember(){
        require(registerMembers[msg.sender],"Member not registered");
        _;
    }

    //添加新的成员
    function addMangers(address _memeber) public onlyBankManager{
        require(_memeber != address(0),"invalid address");
        require(_memeber != msg.sender,"msg.sender already member");
        require(registerMembers[_memeber]==false,"Already registered");
        members.push(_memeber);
        registerMembers[_memeber]=true;
    }

    //查看所有会员
    function getMember() public view returns(address[] memory){
        return members;
    }
    
    //会员向储蓄罐存钱
    // function deposit(uint256 amount) public onlyRegisterMember{
    //     require(amount > 0 ,"invalid amount");
    //     balance[msg.sender] += amount;

    // }

    //取款
    function withdraw(uint256 amount) public onlyRegisterMember{
        require(amount <= balance[msg.sender],"balance not enough ");
        require(amount > 0 , "invalid amount");
        balance[msg.sender] -= amount;
    }

    //存入eth
    function depositAmountEther() public payable onlyRegisterMember{
        require(msg.value > 0 ,"invalid amount");
        balance[msg.sender] += msg.value;
    }

    //查看余额
    function getbalance() public view returns(uint256 ) {
        return balance[msg.sender];
    } 

}