// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    address public owner;

    // 记录注册好友, 包括是否注册, 以及好友列表
    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    // 记录余额
    mapping(address => uint256) public balances;

    // 记录债务信息, 债务人 -> 债权人 -> 债务金额
    mapping(address => mapping(address => uint256)) public debts;

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    // 注册新的好友
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    // 存钱到钱包
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    // 记录债务信息
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");

        debts[_debtor][msg.sender] += _amount;
    }

    // 使用钱包余额偿还债务
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // 更新余额和债务
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

    // 通过transfer 直接转账
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(_amount > 0, "Amount must be greater than 0");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;
    }

    // 通过call转账
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(_amount > 0, "Amount must be greater than 0");

        balances[msg.sender] -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        balances[_to] += _amount;
    }

    // 取款
    function withdraw(uint256 _amount) public onlyRegistered {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    // 检查余额
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
}