// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleIOU {
    
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;

    
    event FriendRegistered(address indexed friend);
    event BalanceUpdated(address indexed friend, uint256 currentBalance);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtCleared(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtForgiven(address indexed debtor, address indexed creditor, uint256 amount);
    event EtherWithdrawn(address indexed friend, uint256 amount);
    event EtherTransferred(address indexed from, address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
        emit FriendRegistered(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "Not registered");
        _;
    }
    
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Already registered");
        
        registeredFriends[_friend] = true;
        friendList.push(_friend);
        emit FriendRegistered(_friend);
    }
    
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit BalanceUpdated(msg.sender, balances[msg.sender]); // نرسل الرصيد الإجمالي
    }
    
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Not registered");
        require(_amount > 0, "Amount > 0");
        
        debts[_debtor][msg.sender] += _amount;
        emit DebtRecorded(_debtor, msg.sender, _amount);
    }

    function debtForgiveness(address _debtor, uint256 _amount) public onlyRegistered {
        require(debts[_debtor][msg.sender] >= _amount, "Exceeds debt");
        
        debts[_debtor][msg.sender] -= _amount;
        emit DebtForgiven(_debtor, msg.sender, _amount);
    }
    
    // Pay debt from wallet
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(debts[msg.sender][_creditor] >= _amount, "Incorrect debt amount");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
        
        emit DebtCleared(msg.sender, _creditor, _amount);
        emit BalanceUpdated(msg.sender, balances[msg.sender]);
        emit BalanceUpdated(_creditor, balances[_creditor]);
    }
    
    // Transfer ETH to another registered friend
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");

        emit EtherTransferred(msg.sender, _to, _amount);
        emit BalanceUpdated(msg.sender, balances[msg.sender]);
    }
    
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit EtherWithdrawn(msg.sender, _amount);
        emit BalanceUpdated(msg.sender, balances[msg.sender]);
    }
    
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
}
