//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//@title 以太坊储蓄罐合约 EtherPiggyBank
//@author yuheng
//@notice 本合约允许注册成员向自己的“储蓄罐”存入或提取 ETH，由管理员管理成员注册
//dev 使用 `payable` 函数接受真实 ETH，并记录余额
contract EtherPiggyBank {
    //@notice 声明状态变量
    address public bankManager;     //声明银行管理员地址（只有管理员可以添加成员）
    address[] members;  //声明所有已注册成员的地址列表
    mapping(address => bool) public registeredMembers;  //成员注册状态映射（true 表示已注册）
    mapping (address => uint256) balance; // 每个成员地址对应的余额（单位：wei）
    //@notice 构造函数：设置管理员,合约部署时，部署者为银行管理员并自动加入成员列表
    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);   // 管理员自动加入成员列表
    }
    //@notice 权限控制修饰符,限制仅银行管理员可调用的函数
    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }
    //@notice 限制仅已注册成员可调用的函数
    modifier onlyRegesteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }
    //@notice 成员管理函数,添加新的注册成员
    //@param _member 要添加的成员地址
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0),"Invalid address");   // 不允许零地址
        require(_member != msg.sender, "Bank Manager is already a member"); // 管理员默认已是成员
        require(!registeredMembers[_member], "Member already registered");  // 不允许重复注册
        registeredMembers[_member] = true;
        members.push(_member);
    }
    // @notice 获取所有已注册成员的地址数组
    function getMembers() public view returns(address[] memory) {
        return members;
    }

    /* 用于逻辑金额存入（非 ETH 实际转账）,deposit amount
        function depositAmount(uint256 _member) public onlyRegesteredMember {   // 限定仅已注册成员可存款
        require(msg.value > 0, "Invalid amount");     // 不允许零金额
        balance[msg.sender] = balance[msg.sender]+_amount;    // 存入资金后，更新余额
        }
    */

    //@notice 存款（单位：以太币）,向自己的储蓄罐存入 ETH（合约接收资金）,deposit in Ether
    //@dev 使用 `msg.value` 记录传入金额
        function depositAmountEther() public payable onlyRegesteredMember {   // 限定仅已注册成员可存款
        require(msg.value > 0, "Invalid amount");     // 不允许零金额
        balance[msg.sender] += msg.value;    // 存入资金后，更新余额
        }
    //@notice 提款（从储蓄罐中扣除余额，但不实际转出 ETH）
    //@param _amount 要提取的金额
    //@dev 使用 `msg.value` 记录传入金额
        function withdrawAmount(uint256 _amount) public onlyRegesteredMember {   // 限定仅已注册成员可存款
        require(_amount > 0, "Invalid amount");     // 不允许零金额
        require(balance[msg.sender] >= _amount, "Insufficient balance");    // 扣除资金后，更新余额
        balance[msg.sender] = balance[msg.sender]-_amount;
        }
    // @notice 查询任意成员当前余额
    // @param _member 要查询的成员地址
    // @return 返回该地址的余额（单位：wei）
    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];  // 查询当前余额
    }
}