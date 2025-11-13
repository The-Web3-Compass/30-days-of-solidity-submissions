//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;
    
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    
    mapping(address => uint256) public balances;
    
    mapping(address => mapping(address => uint256)) public debts; // debtor -> creditor -> amount
    
    constructor() {
        owner = msg.sender;
        registeredFriends[owner] = true;
        friendList.push(owner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }
    
    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered.");
        _;
    }
    
    function addFriend(address friend) public onlyOwner{
        require(friend != address(0), "Invalid address.");
        require(registeredFriends[friend]==false, "Already registered.");
        
        friendList.push(friend);
        registeredFriends[friend] = true;

    }
  
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Invalid deposit amount.");

        balances[msg.sender] += msg.value;
    }
    
    function recordDebt(address debtor, uint256 amount) public onlyRegistered {
        require(amount > 0, "Invalid amount.");
        require(debtor != address(0), "Invalid address.");
        require(registeredFriends[debtor], "Debtor not registered.");

        debts[debtor][msg.sender] += amount;
    }
    
    function payFromWallet(address creditor, uint256 amount) public onlyRegistered {
        require(amount > 0, "Invalid amount.");
        require(creditor != address(0), "Invalid address.");
        require(registeredFriends[creditor], "Creditor not registered.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        require(debts[msg.sender][creditor] >= amount, "Debt amount incorrect");

        balances[msg.sender] -= amount;
        balances[creditor] += amount;
        debts[msg.sender][creditor] -= amount;
    }
    
    function transferEtherViaCall(address payable to, uint256 amount) public onlyRegistered {
        require(to != address(0), "Invalid address.");
        require(amount > 0, "Invalid amount.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        
        balances[msg.sender] -= amount;
        (bool success, ) = to.call{value: amount}("");
        balances[to] += amount;
        require(success, "Transfer failed.");
    }
    
    function withdraw(uint256 amount) public onlyRegistered {
        require(amount > 0, "Invalid amount.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");

        balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }  
    
    function checkBalance() public view onlyRegistered returns(uint256) {
        return balances[msg.sender];
    }
}