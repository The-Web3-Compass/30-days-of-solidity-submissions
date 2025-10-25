// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Simple {
    address public owner; // 所有者
    mapping(address => bool) public registeredFriends; // 已注册好友
    address[] public friendList; // 好友列表
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts; // 债
    constructor(){
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }
    // 所有者
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    // 已注册
    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }
    // 添加朋友
    function addFriends(address _friend) public onlyOwner{
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");
        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }
    // 存款到钱包
    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }
    // 记录债务
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered{
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");

        debts[_debtor][msg.sender] += _amount;
    }
    // 从钱包支付
    function payFromWallet(address _creditor, uint256 _amount)public onlyRegistered{
        require(_creditor != address(0),"Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[_creditor][msg.sender] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }
    // transfer 发送ETH
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to != address(0), "Invalid address");
        require(_amount > 0, "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;
    }
    // 使用call 发送
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to != address(0), "Invalid address");
        require(_amount > 0, "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        balances[_to] += _amount;
        _to.transfer(_amount);
        require(success, "Transfer failed");
    }
    // 撤回
    function withdraw(uint256 _amount) public onlyRegistered{
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}('');
        require(success, "Withdrawal failed");
    }
    // 查看ETH 余额
    function checkBalance() public view onlyRegistered returns(uint256) {
        return balances[msg.sender];
    }
}