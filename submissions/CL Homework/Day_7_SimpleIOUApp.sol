//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;
    
    // Track registered friends
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    
    // Track balances
    mapping(address => uint256) public balances;
    
    // Simple debt tracking
    mapping(address => mapping(address => uint256)) public debts; // debtor -> creditor -> amount
    
    // Event log
    event PayDebt(address indexed _debtor, address indexed _creditor, uint256 amount);
    event RecordDebt(address indexed _debtor, address indexed _creditor, uint256 amount);
    event WaiveDebt(address indexed _debtor, address indexed _creditor, uint256 amount);
    event Deposit(address indexed _registor, uint256 amount);


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
    
    // Record that someone owes you money
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        debts[_debtor][msg.sender] += _amount;
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

    // Debt forgiveness
    function debtForgiveness(address _forgiveTo, uint256 _amount) public onlyRegistered {
        require(_forgiveTo != address(0), "Invalid address");
        require(registeredFriends[_forgiveTo], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[_forgiveTo][msg.sender] >= _amount, "Debt amount incorrect");

        debts[_forgiveTo][msg.sender] -= _amount;
    }
    
    // Group Split
    function groupSplit(address _payer, address[] memory _participants, uint256 _amount) public onlyOwner {
        require(_payer != address(0), "Invalid payer address");
        require(registeredFriends[_payer], "Payer not registered");
        for (uint i = 0; i < _participants.length; i++) {
            address _participant = _participants[i];
            if (!registeredFriends[_participant]) {
                addFriend(_participant);
            }

            // Add Debt
            debts[_participant][_payer] += _amount / _participants.length;
        }

    }

    // Alternative transfer method using call()
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
                
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        balances[msg.sender] -= _amount;
        balances[_to]+=_amount;

    }
    
    // Withdraw your balance
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
        balances[msg.sender] -= _amount;
    }
    
    // Check your balance
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
}
