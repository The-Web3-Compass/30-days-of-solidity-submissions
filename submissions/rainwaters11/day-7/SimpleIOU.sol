// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    // State Variables
    address public owner;
    address[] public friendList;
    mapping(address => bool) public registeredFriends;
    mapping(address => uint256) public balances;
    
    // Nested Mapping: debts[debtor][creditor] = amount
    mapping(address => mapping(address => uint256)) public debts;

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    // --- Group Management ---
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    // --- Wallet Mechanics ---
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    // Using the secure 'call' method and Checks-Effects-Interactions pattern
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Effect (Deduct balance BEFORE transferring)
        balances[msg.sender] -= _amount;

        // Interaction
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }

    // --- IOU Mechanics ---
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");

        // The person calling this function is the creditor recording the debt
        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Update internal balances
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        
        // Reduce the debt
        debts[msg.sender][_creditor] -= _amount;
    }

    // EXTENDED CHALLENGE: Debt Forgiveness
    // Allows a creditor to cancel a debt without requiring an ETH transfer
    function forgiveDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(registeredFriends[_debtor], "Debtor not registered");
        require(debts[_debtor][msg.sender] >= _amount, "Cannot forgive more than owed");
        
        debts[_debtor][msg.sender] -= _amount;
    }
}
