//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnhancedIOU {
    address public owner;
    
    // Track registered friends
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    
    // Track balances
    mapping(address => uint256) public balances;
    
    // Simple debt tracking
    mapping(address => mapping(address => uint256)) public debts; // debtor -> creditor -> amount
    
    // Group splits tracking
    struct Split {
        address payer;
        address[] participants;
        uint256 totalAmount;
        uint256 amountPerPerson;
        mapping(address => bool) hasPaid;
        bool isActive;
    }
    
    mapping(uint256 => Split) public splits;
    uint256 public nextSplitId;
    
    // Events
    event FriendAdded(address indexed owner, address indexed friend);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtPaid(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtForgiven(address indexed debtor, address indexed creditor, uint256 amount);
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);
    event SplitCreated(uint256 indexed splitId, address indexed payer, uint256 totalAmount, uint256 amountPerPerson);
    event SplitContributed(uint256 indexed splitId, address indexed participant, uint256 amount);
    event SplitCompleted(uint256 indexed splitId);
    
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
        
        emit FriendAdded(msg.sender, _friend);
    }
    
    // Deposit funds to your balance
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    // Record that someone owes you money
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        debts[_debtor][msg.sender] += _amount;
        
        emit DebtRecorded(_debtor, msg.sender, _amount);
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
        
        emit DebtPaid(msg.sender, _creditor, _amount);
    }
    
    // NEW: Forgive debt owed to you
    function forgiveDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Debtor not registered");
        require(debts[_debtor][msg.sender] >= _amount, "Debt amount incorrect");
        
        debts[_debtor][msg.sender] -= _amount;
        
        emit DebtForgiven(_debtor, msg.sender, _amount);
    }
    
    // NEW: Create a group split
    function createSplit(address[] memory _participants, uint256 _totalAmount) public onlyRegistered returns (uint256) {
        require(_participants.length > 0, "Need at least one participant");
        require(_totalAmount > 0, "Amount must be greater than 0");
        
        // Calculate amount per person (including the payer)
        uint256 totalParticipants = _participants.length + 1; // +1 for the payer
        uint256 amountPerPerson = _totalAmount / totalParticipants;
        
        uint256 splitId = nextSplitId++;
        
        // Initialize the split
        Split storage newSplit = splits[splitId];
        newSplit.payer = msg.sender;
        newSplit.participants = _participants;
        newSplit.totalAmount = _totalAmount;
        newSplit.amountPerPerson = amountPerPerson;
        newSplit.isActive = true;
        
        // Record debts automatically for each participant
        for (uint i = 0; i < _participants.length; i++) {
            require(registeredFriends[_participants[i]], "Participant not registered");
            // Each participant owes the payer their share
            debts[_participants[i]][msg.sender] += amountPerPerson;
            emit DebtRecorded(_participants[i], msg.sender, amountPerPerson);
        }
        
        emit SplitCreated(splitId, msg.sender, _totalAmount, amountPerPerson);
        return splitId;
    }
    
    // NEW: Contribute to a split payment
    function contributeToSplit(uint256 _splitId) public onlyRegistered {
        Split storage split = splits[_splitId];
        require(split.isActive, "Split is not active");
        
        bool isParticipant = false;
        for (uint i = 0; i < split.participants.length; i++) {
            if (split.participants[i] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        
        require(isParticipant, "You are not part of this split");
        require(!split.hasPaid[msg.sender], "You have already paid your share");
        require(balances[msg.sender] >= split.amountPerPerson, "Insufficient balance");
        
        // Transfer funds from participant to payer
        balances[msg.sender] -= split.amountPerPerson;
        balances[split.payer] += split.amountPerPerson;
        
        // Mark as paid and reduce debt
        split.hasPaid[msg.sender] = true;
        debts[msg.sender][split.payer] -= split.amountPerPerson;
        
        emit SplitContributed(_splitId, msg.sender, split.amountPerPerson);
        emit DebtPaid(msg.sender, split.payer, split.amountPerPerson);
        
        // Check if all participants have paid
        bool allPaid = true;
        for (uint i = 0; i < split.participants.length; i++) {
            if (!split.hasPaid[split.participants[i]]) {
                allPaid = false;
                break;
            }
        }
        
        if (allPaid) {
            split.isActive = false;
            emit SplitCompleted(_splitId);
        }
    }
    
    // Direct transfer method using transfer()
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;
        
        emit FundsTransferred(msg.sender, _to, _amount);
    }
    
    // Alternative transfer method using call()
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        balances[_to] += _amount;
        
        emit FundsTransferred(msg.sender, _to, _amount);
    }
    
    // Withdraw your balance
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(msg.sender, _amount);
    }
    
    // Check your balance
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
    
    // Get all friends
    function getAllFriends() public view returns (address[] memory) {
        return friendList;
    }
    
    // Check debt between two parties
    function checkDebt(address _debtor, address _creditor) public view returns (uint256) {
        return debts[_debtor][_creditor];
    }
    
    // Get split details (not including participant payment status)
    function getSplitDetails(uint256 _splitId) public view returns (
        address payer,
        uint256 totalAmount,
        uint256 amountPerPerson,
        bool isActive,
        address[] memory participants
    ) {
        Split storage split = splits[_splitId];
        return (
            split.payer,
            split.totalAmount,
            split.amountPerPerson,
            split.isActive,
            split.participants
        );
    }
    
    // Check if a participant has paid in a split
    function hasPaidSplit(uint256 _splitId, address _participant) public view returns (bool) {
        return splits[_splitId].hasPaid[_participant];
    }
}
