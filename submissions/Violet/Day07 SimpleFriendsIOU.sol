// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFriendsIOU {
    address public owner;
    
    // Track registered friends
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    
    // Track balances
    mapping(address => uint256) public balances;
    
    // Simple debt tracking
    mapping(address => mapping(address => uint256)) public debts; // debtor -> creditor -> amount
    
    // Debt records for detailed tracking
    struct Debt {
        address debtor;
        address creditor;
        uint256 amount;
        string description;
        bool isPaid;
    }
    
    mapping(uint256 => Debt) public debtRecords;
    uint256 public nextDebtId;
    
    event DebtCreated(uint256 debtId, address debtor, address creditor, uint256 amount);
    event DebtPaid(uint256 debtId);
    
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
    
    // Register a new friend
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");
        
        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }
    
    // Deposit funds to your balance
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }
    
    // Record that someone owes you money with description
    function recordDebt(address _debtor, uint256 _amount, string memory _description) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        debts[_debtor][msg.sender] += _amount;
        
        // Create detailed record
        debtRecords[nextDebtId] = Debt({
            debtor: _debtor,
            creditor: msg.sender,
            amount: _amount,
            description: _description,
            isPaid: false
        });
        
        emit DebtCreated(nextDebtId, _debtor, msg.sender, _amount);
        nextDebtId++;
    }
    
    // Pay off debt using internal balance transfer
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // Update balances and debt
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }
    
    // Transfer ether to another registered friend
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
    
    // Withdraw your balance
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
    
    // Check your balance
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
    
    // Get debt between two addresses
    function getDebt(address _debtor, address _creditor) public view returns (uint256) {
        return debts[_debtor][_creditor];
    }
    
    // Get debt record details
    function getDebtRecord(uint256 _debtId) public view returns (address, address, uint256, string memory, bool) {
        Debt memory debt = debtRecords[_debtId];
        return (debt.debtor, debt.creditor, debt.amount, debt.description, debt.isPaid);
    }
    
    // Get list of all friends
    function getFriendList() public view returns (address[] memory) {
        return friendList;
    }
}