//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdvancedIOU {
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;

    event FriendAdded(address indexed friend);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event DebtRecorded(address indexed creditor, address indexed debtor, uint256 amount);
    event DebtSettled(address indexed debtor, address indexed creditor, uint256 amount);

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
    
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");
        
        registeredFriends[_friend] = true;
        friendList.push(_friend);
        emit FriendAdded(_friend);
    }
    
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Debtor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        debts[_debtor][msg.sender] += _amount;
        emit DebtRecorded(msg.sender, _debtor, _amount);
    }

    function settleDebt(address _creditor, uint256 _amount) public onlyRegistered {
        require(registeredFriends[_creditor], "Creditor not registered");
        require(debts[msg.sender][_creditor] >= _amount, "Amount exceeds your debt to this creditor.");

        uint theirDebtToYou = debts[_creditor][msg.sender];
        
        if (theirDebtToYou >= _amount) {
            debts[_creditor][msg.sender] -= _amount;
        } else {
            uint amountToPayFromBalance = _amount - theirDebtToYou;
            require(balances[msg.sender] >= amountToPayFromBalance, "Insufficient balance to settle remaining debt.");
            
            if (theirDebtToYou > 0) {
                debts[_creditor][msg.sender] = 0;
            }
            
            balances[msg.sender] -= amountToPayFromBalance;
            balances[_creditor] += amountToPayFromBalance;
        }
        
        debts[msg.sender][_creditor] -= _amount;
        emit DebtSettled(msg.sender, _creditor, _amount);
    }
    
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit Withdrawn(msg.sender, _amount);
    }

    function getDebt(address _debtor, address _creditor) public view returns (uint256) {
        return debts[_debtor][_creditor];
    }
}