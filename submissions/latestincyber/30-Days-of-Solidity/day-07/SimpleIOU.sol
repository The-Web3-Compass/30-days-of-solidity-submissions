// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true; 
        friendList.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered.");
        _;
    }

    function registerFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH.");
        balances[msg.sender] += msg.value;
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(_debtor != msg.sender, "Cannot owe yourself");
        require(registeredFriends[_debtor], "Address not registered.");
        require(_amount > 0, "Amount must be greater than zero");

        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(_creditor != msg.sender, "Cannot pay yourself");
        require(registeredFriends[_creditor], "Address not registered.");
        require(_amount > 0, "Amount must be greater than zero");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect.");
        require(balances[msg.sender] >= _amount, "Insufficient balance in wallet.");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(_to != msg.sender, "Cannot transfer to yourself");
        require(registeredFriends[_to], "Recipient not registered.");
        require(_amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= _amount, "Insufficient balance in wallet.");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;
    }

    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(_to != msg.sender, "Cannot transfer to yourself");
        require(registeredFriends[_to], "Recipient not registered.");
        require(_amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= _amount, "Insufficient balance in wallet.");

        balances[msg.sender] -= _amount;

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed.");
        balances[_to] += _amount;
    }

    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance in wallet.");

        balances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed.");
    }

    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
}