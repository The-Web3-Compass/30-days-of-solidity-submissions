// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SavingGroup{
    address public bankManager;
    address[] public members;
    mapping (address => bool) public registeredMembers;
    mapping (address => uint256) balance;

    //为每个成员添加一个取现冷却期
    mapping (address => uint256) withdrawTimer;
    //取现冷却期为300s
    uint256 timer = 300;

    constructor(){
        bankManager = msg.sender;
        registeredMembers[msg.sender] = true;
        //记录初始时间
        withdrawTimer[msg.sender] = block.timestamp;
        members.push(msg.sender);
    }

    modifier OnlyBankManager(){
        require(msg.sender == bankManager,"Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender],"Member not registered");
        _;
    }

    function addMembers(address _member) public OnlyBankManager{
        require(_member != address(0),"Invalid address");
        require(!registeredMembers[_member],"This member is already registered");

        registeredMembers[_member] = true;
        //记录初始时间
        withdrawTimer[_member] = block.timestamp;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    function deposit() public payable onlyRegisteredMember{
        require(msg.value>0,"Invalid amount");
        balance[msg.sender]+=msg.value;
    }

    function getBalanceDetail()public view onlyRegisteredMember returns(uint256){
        return balance[msg.sender];
    }

    //取现函数，可以把以太币返还给用户
    function withdraw(uint256 _amount)public onlyRegisteredMember{
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(_amount <= balance[msg.sender], "Insufficient balance for withdrawal");
        require(block.timestamp>withdrawTimer[msg.sender], "5-minute wait between withdrawals");

        balance[msg.sender]-=_amount;
        //利用transfer将合约的ETH传回给调用者
        //send” 和 “transfer” 仅适用于 “address payable” 类型的对象，不适用于 “address” 类型。
        //msg.sender（当前函数调用者地址）和 tx.origin（整个交易的发起者地址）是 Solidity 内置的全局变量，默认类型是 address，需显式转换为 address payable
        payable (msg.sender).transfer(_amount);
        withdrawTimer[msg.sender]=block.timestamp+timer;
    }


}