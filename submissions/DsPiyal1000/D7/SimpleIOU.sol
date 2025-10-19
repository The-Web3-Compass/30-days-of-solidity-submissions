// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleIOU {
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;
    
    // Reentrancy guard
    bool private locked;
    
    event FriendAdded(address indexed friend);
    event Deposit(address indexed from, uint256 amount);
    event DebtRecorded(address indexed creditor, address indexed debtor, uint256 amount);
    event DebtForgiven(address indexed creditor, address indexed debtor, uint256 amount);
    event GroupSplit(address indexed initiator, uint256 totalAmount, uint256 perPerson);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed by, uint256 amount);

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the Owner");
        _;
    }

    modifier onlyRegistered {
        require(registeredFriends[msg.sender], "You're not registered");
        _;
    }
    
    modifier nonReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    function addFriends(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid Address");
        require(!registeredFriends[_friend], "Already added");
        registeredFriends[_friend] = true;
        friendList.push(_friend);
        emit FriendAdded(_friend);
    }

    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "You did not send any value");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid Address");
        require(registeredFriends[_debtor], "Not a registered friend");
        require(_amount > 0, "Amount cannot be zero or negative");
        debts[_debtor][msg.sender] += _amount;
        emit DebtRecorded(msg.sender, _debtor, _amount);
    }

    function forgiveDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid Address");
        require(registeredFriends[_debtor], "Not a registered friend");
        require(debts[_debtor][msg.sender] >= _amount, "Insufficient debt to forgive");
        
        unchecked {
            debts[_debtor][msg.sender] -= _amount;
        }
        
        emit DebtForgiven(msg.sender, _debtor, _amount);
    }

    function splitDebtEqually(uint256 _totalAmount) public onlyRegistered {
        require(_totalAmount > 0, "Total amount must be greater than zero");
        uint256 totalFriends = friendList.length;
        require(totalFriends > 1, "Need more than one friend to split");

        uint256 activeFriends = 0;
        for (uint256 i = 0; i < totalFriends; i++) {
            if (friendList[i] != msg.sender) {
                activeFriends++;
            }
        }
        
        require(activeFriends > 0, "No friends to split with");
        uint256 perPerson = _totalAmount / activeFriends;
        
        for (uint256 i = 0; i < totalFriends; i++) {
            address friend = friendList[i];
            if (friend != msg.sender) {
                debts[friend][msg.sender] += perPerson;
            }
        }
        emit GroupSplit(msg.sender, _totalAmount, perPerson);
    }

    function transferFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid Address");
        require(registeredFriends[_creditor], "Not a registered friend");
        require(_amount > 0, "Amount cannot be zero or negative");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(debts[msg.sender][_creditor] >= _amount, "Insufficient debt");

        unchecked {
            debts[msg.sender][_creditor] -= _amount;
            balances[msg.sender] -= _amount;
        }
        balances[_creditor] += _amount;
        
        emit Transfer(msg.sender, _creditor, _amount);
    }

    function transferEther(address _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid Address");
        require(registeredFriends[_to], "Not a registered friend");
        require(_amount > 0, "Amount cannot be zero or negative");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        unchecked {
            balances[msg.sender] -= _amount;
        }
        balances[_to] += _amount;
        
        emit Transfer(msg.sender, _to, _amount);
    }

    function transferEtherCall(address payable _to, uint256 _amount) public nonReentrant onlyRegistered {
        require(_to != address(0), "Invalid Address");
        require(registeredFriends[_to], "Not a registered friend");
        require(_amount > 0, "Amount cannot be zero or negative");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        unchecked {
            balances[msg.sender] -= _amount;
        }
        
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to transfer");
        
        emit Transfer(msg.sender, _to, _amount);
    }

    function withdraw(uint256 _amount) public nonReentrant onlyRegistered {
        require(_amount > 0, "Amount cannot be zero or negative");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        unchecked {
            balances[msg.sender] -= _amount;
        }
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Failed to withdraw");
        
        emit Withdraw(msg.sender, _amount);
    }

    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
    
    function checkDebt(address _creditor) public view onlyRegistered returns (uint256) {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Not a registered friend");
        return debts[msg.sender][_creditor];
    }
    
    function checkDebtOwed(address _debtor) public view onlyRegistered returns (uint256) {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Not a registered friend");
        return debts[_debtor][msg.sender];
    }
    
    // Get total number of registered friends
    function getFriendCount() public view returns (uint256) {
        return friendList.length;
    }
    
    // Check if the contract has enough balance to cover all internal balances
    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}