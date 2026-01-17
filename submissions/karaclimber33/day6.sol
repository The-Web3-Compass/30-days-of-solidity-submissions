//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    //主理人
    //成员
    address public bankManager;
    address[] public members;
    mapping(address=>bool) registeredMember;//标记一下是否已注册
    mapping (address=>uint256) balance;//存了多少钱

    //初始化，设置主理人（构造函数
    constructor(){
        bankManager=msg.sender;
        registeredMember[msg.sender]=true;
    }
    
    //违规行为小警察机器人（修饰符
    modifier onlyBankManager{
        require(msg.sender==bankManager,"Only Bank manager can perform this action.");
        _;
    }
    modifier onlyBankMembers{
       // require(msg.sender==bankM)
       //这就是需要标识符的原因，可以判断用户是否已注册，无需遍历只需要看标记
       require(!registeredMember[msg.sender],"Only Bank members can perform this action.");
       _;
    }

    //添加成员
    function addMember(address newMember) public onlyBankManager{
        //得设置限制
        //有效地址
        //不能重复添加
        //不能添加自己
        
        require(newMember!=address(0),"The address is invalid.");
        require(newMember!=bankManager,"Bank Manager can not be a member.");
        require(!registeredMember[newMember],"The address is already a member.");
       
        members.push(newMember);
        registeredMember[msg.sender]=true;
    }

    //显示成员
    function membersList()public view returns (address[] memory){
        return members;
    }

    //存钱
    function saveMoney(uint256 _amount) public onlyBankMembers{
        //限制
        //不能存零元
        require(_amount>0,"Invalid amount!");

        balance[msg.sender]+=_amount;

    }

    //取钱
    function withdrawMoney(uint256 _amount) public onlyBankMembers{
       //限制
       //不能取大于余额的数
       require(balance[msg.sender]-_amount>0,"You don't have enough money!");//Insufficient balance
       require(_amount>0,"Invalid amount!");

       
        balance[msg.sender]-=_amount;
    }

    //查询余额
    function checkBalance() public view returns(uint256){
        return balance[msg.sender];

    }

    //存以太坊币
    function depositAmountEther()public payable onlyBankMembers{
        require(msg.value>0,"Invalid amount");
        balance[msg.sender]+=msg.value;
    }



    
}