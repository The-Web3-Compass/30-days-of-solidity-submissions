// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank{
    
    // 银行管理员
    address private bankManager;
    //成员地址数组
    address[] memberList;
    // 成员是否添加权限
    mapping(address=>bool) private registeredMembers;
    //每个成员存款余额 单位Wei
    mapping(address=>uint) private balance;

    constructor(){
        bankManager = msg.sender;
        memberList.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }

    // 只有管理员可调用的函数
    modifier checkManager(){
        require(bankManager == msg.sender,unicode"不是管理员，不能操作");
        _;
    }

    //只有注册成员可调用的函数
    modifier checkRegester(){
        require(registeredMembers[msg.sender],unicode"不是已注册成员，不可以操作");        
        _;
    }

    // 成员注册
    function registe(address _account) public  checkManager{
        require(_account != address(0),unicode"不可为零地址");
        require(!registeredMembers[_account],unicode"该成员已注册，不可重复注册");
        require(_account != msg.sender,unicode"管理员在发布时已经自动注册，无需重复注册");

        memberList.push(_account);
        registeredMembers[_account] = true;
    }

    // 查询所有已注册成员地址
    function getAllMembers() public view  returns (address[] memory){
        return memberList;
    }

    /*
        存款   限定仅已注册成员可存款
        payable 修饰的方法才能接受mag.value进行实质交易 
        本方法只进行了内部数值记录，未真实交易
    */
    function depositAmountEther() public payable checkRegester {  
        require(msg.value > 0, unicode"不允许交易数值为零");
        balance[msg.sender] += msg.value;
    }

    //取款
    function withdrawAmount(uint _amount) public checkRegester{
        require(_amount > 0, unicode"不允许交易数值为零");
        require(_amount < balance[msg.sender],unicode"账户余额不足");
        balance[msg.sender] -= _amount;

    }

    //查询当前账户余额
    function getRegestValue(address _account) public view checkRegester returns (uint ){
        require(_account != address(0),unicode"不可为零地址");
        return balance[_account];
    }

}