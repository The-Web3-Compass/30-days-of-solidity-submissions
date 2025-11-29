//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;//生命所有者

    mapping(address=>bool) public registeredFriends;//地址映射是否是注册朋友
    address[] public friendList;

    mapping(address=>uint256) public balances;//地址映射余额

    mapping(address => mapping(address => uint256)) public debts;//欠款人分别欠了谁多少钱

    constructor(){//初始化owner并把它加入好友列表
        owner=msg.sender;
        registeredFriends[msg.sender]=true;
        friendList.push(msg.sender);
    }
//定义只有owner的操作
    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }
//定义只有登记用的操作
    modifier onlyRegistered(){
        require(registeredFriends[msg.sender],"You are not registered");
        _;
    }
//添加朋友
    function addFriend(address _friend) public onlyOwner returns(address) {
        require(_friend!= address(0),"Invalid address");
        require(!registeredFriends[_friend],"Friend already registered");

        registeredFriends[_friend]=true;
        friendList.push(_friend);
        return(_friend);
    }
//存钱
    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value>0,"Must sent ETH");
        balances[msg.sender]+=msg.value;
    }
//记录欠款
    function recordDebt(address  _debtor,uint256 _amount) public onlyRegistered{
        require( _debtor!=address(0),"Invalid address");
        require(registeredFriends[ _debtor],"address not registered.");
        require(_amount>0,"amount must be greater than0");

        debts[ _debtor][msg.sender] += _amount;
    }
//换欠款
    function PayFromWallet(address _creditor, uint _amount) public onlyRegistered{
        require(_creditor!=address(0),"Invalid address");
        require(registeredFriends[_creditor],"address not registered.");
        require(_amount>0,"amount must be greater than0");
        require(debts[msg.sender][_creditor] >= _amount,"Debt amount incorrect");
        require(balances[msg.sender]>=_amount,"Insufficient balance");
//更新账本
        balances[msg.sender]-=_amount;
        balances[_creditor]+=_amount;
        debts[msg.sender][_creditor]-=_amount;
    }
//转账
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered{

        require(_to!=address(0),"Invalid address");
        require(registeredFriends[_to],"address not registered.");
        require(_amount>0,"amount must be greater than 0");
        require(balances[msg.sender]>=_amount,"Insufficient balance");

        
         balances[msg.sender] -= _amount;
         balances[_to] += _amount;
         
         (bool success,)= _to.call{value: _amount}("");//call 方法向 _to 地址发送 _amount ETH。
         require(success, "transfer failed");

        
    }
//取款
    function withdraw(uint256 _amount) public onlyRegistered{
        require(msg.sender!=address(0),"Invalid address");
        require(registeredFriends[msg.sender],"address not registered.");
        require(_amount>0,"amount must be greater than 0");
        require(balances[msg.sender]>=_amount,"Insufficient balance");

       

        balances[msg.sender] -= _amount;

        (bool success,)= payable(msg.sender).call{value: _amount}("");
        require(success, "transfer failed");
    }
//检查余额
    function checkBalance() public view onlyRegistered returns(uint256){
        return balances[msg.sender];
    }
}
