// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleIOU {
    address public manager;
    address[] public friends;
    mapping(address => bool) public friendToRegistered;

    mapping(address => uint256) public friendToBalance;
    // 嵌套 map, A 欠 B 多少钱
    // friendToDebtAmount[A][B] = 100; 意味着 A 欠 B 100 块钱
    mapping(address => mapping(address => uint256)) public friendToDebtAmount;

    constructor() {
        manager = msg.sender;
        friendToRegistered[msg.sender] = true;
        friends.push(msg.sender);
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(friendToRegistered[msg.sender], "You are not registered");
        _;
    }

    function addFriend(address _friend) public onlyManager {
        require(_friend != address(0), "Invalid address");
        require(!friendToRegistered[_friend], "Friend already registered");

        friendToRegistered[_friend] = true;
        friends.push(_friend);
    }

    // 存钱
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Invalid amount");
        friendToBalance[msg.sender] += msg.value;
    }

    // 记账
    function recordDebt(address _friend, uint256 _amount) public onlyRegistered {
        require(_friend != address(0), "Invalid address");
        require(friendToRegistered[_friend], "Friend not registered");
        require(_amount > 0, "Invalid amount");

        friendToDebtAmount[msg.sender][_friend] += _amount;
    }

    // 还钱
    function payFromWallet(address _friend, uint256 _amount) public onlyRegistered {
        require(_friend != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");
        require(friendToRegistered[_friend], "Friend not registered");
        require(friendToDebtAmount[msg.sender][_friend] >= _amount, "Debt amount incorrect");
        require(friendToBalance[msg.sender] >= _amount, "Insufficient balance");

        // 相当于一种转账，把 msg.sender 的钱转到 _friend 的钱包里
        friendToBalance[msg.sender] -= _amount;
        friendToBalance[_friend] += _amount;
        friendToDebtAmount[msg.sender][_friend] -= _amount;
    }

    // 转账
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");
        require(friendToRegistered[_to], "Recipient not registered");
        require(friendToBalance[msg.sender] >= _amount, "Insufficient balance");

        friendToBalance[msg.sender] -= _amount;
        _to.transfer(_amount);
        friendToBalance[_to] += _amount;
    }

    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(friendToRegistered[_to], "Recipient not registered");
        require(friendToBalance[msg.sender] >= _amount, "Insufficient balance");

        friendToBalance[msg.sender] -= _amount;
        (bool success,) = _to.call{value: _amount}("");
        friendToBalance[_to] += _amount;
        require(success, "Transfer failed");
    }

    function withdraw(uint256 _amount) public onlyRegistered {
        require(friendToBalance[msg.sender] >= _amount, "Insufficient balance");

        friendToBalance[msg.sender] -= _amount;
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");

    }

    function getBalance() public view onlyRegistered returns (uint256) {
        return friendToBalance[msg.sender];
    }
}