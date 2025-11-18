// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SaveMoney {
    //基本信息
    address public bankManager;//拥有批准新成员的能力
    address [] public members;

    mapping (address=>bool) isRegistered; 
    mapping (address=>uint256) balance;

    //构造函数
    constructor(){
        bankManager=msg.sender;
        members.push(bankManager);
    }
    //修饰符
    modifier onlyBM{
        require(msg.sender==bankManager,"Only bank manager can perform this action");
        _;
    }
    modifier onlyRgMebs{
        require(isRegistered[msg.sender], "Member not registered");
        _;
    }


    //创建用户
    function addMebs(address _meb)public onlyBM{
        require(_meb!=address(0),"Invalid address");
        require(_meb!=msg.sender,"Bank Manager is already a member");
        require(!isRegistered[_meb],"Member already registered");
        
        isRegistered[_meb]=true;
        members.push(_meb);
    }
    //查看用户
    function getMebs() public view returns(address [] memory){
        return members;
    }
    //存钱
    function deposit() public payable onlyRgMebs{
        require(msg.value>0,"Invalid amount");
        balance[msg.sender] +=msg.value;
    }
    //取钱
     function withdraw(uint256 _amount) public onlyRgMebs{
        require(_amount>0,"Invalid amount");
        require(balance[msg.sender]>=_amount,"Insufficient balance");
        balance[msg.sender]-=_amount;
        payable(msg.sender).transfer(_amount);
    }
    //查看余额
    
    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 

}