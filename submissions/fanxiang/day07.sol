// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOUContract {
    adress public owner;
    mapping(address => bool) public registerFriends;
    adress[] public friendList;
    mapping(address => uint256) public balance;
    mapping(adress => mapping(adress => uint256)) public debts

    constructor() {
        owner = msg.sender;
        registerFriends[owner] = true;
        friendList.push(owner);
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    modifier onlyRegistered() {
        require(registerFriends[msg.sender], "Only registered friends can call this function");
        _;

    }
    function registerFriend(adress _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registerFriends[_friend], "Friend is already registered");
        registerFriends[_friend] = true;
        friendList.push(_friend);
    }
    function depositIntoWallet() public payable onlyRegistered { 
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balance[msg.sender] += msg.value;
    }
    function recordDebt(adress _debtor, uint256 _amount) public onlyRegistered { 
        require(_debtor != address(0), "Invalid address");
        require(registerFriends[_debtor], "Debtor is not registered")
        require(_amount > 0, "Debt amount must be greater than zero");
        debts[msg.sender][_debtor] += _amount;
    }
    function payFromWallet(adress _creditor, uint256 _amount) public onlyRegistered { 
        require(_creditor != address(0), "Invalid address");
        require(registerFriends[_creditor], "Creditor is not registered");
        require(_amount > 0, "Payment amount must be greater than zero");
        require(debts[_creditor][msg.sender] >= _amount, "Insufficient debt");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
        balance[_creditor] += _amount;
        debts[_creditor][msg.sender] -= _amount;
    }
    function transferEther(adress payable _to, uint256 _amount) public
    onlyRegistered { 
        require(_to != address(0), "Invalid address");
        require(registerFriends[_to], "Recipient is not registered");
        require(_amount > 0, "Transfer amount must be greater than zero");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
        _to.transfer(_amount);
        balance[_to] += _amount;
    }
    function transferEtherViaCall(adress payable _to, uint256 _amount) public
    onlyRegistered { 
        require(_to != address(0), "Invalid address");
        require(registerFriends[_to], "Recipient is not registered");
        require(_amount > 0, "Transfer amount must be greater than zero");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        balance[_to] += _amount;
        require(success, "Transfer failed");
    }
    function withdraw(uint256 _amount) public onlyRegistered { 
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        balance[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
    function checkBalance() public view onlyRegistered returns (uint256) { 
        return balance[msg.sender];
    }
}