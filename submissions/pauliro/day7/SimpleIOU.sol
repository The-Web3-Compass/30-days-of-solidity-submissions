// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
    Build a simple IOU contract for a private group of friends. 
    Each user can deposit ETH, track personal balances, log who owes who, 
    and settle debts — all on-chain. 
    You’ll learn how to accept real Ether using `payable`, transfer 
    funds between addresses, and use nested mappings to represent relationships 
    like 'Alice owes Bob'. This contract mirrors real-world borrowing and lending, 
    and teaches you how to model those interactions in Solidity.
*/

contract SimpleIOU {
    //owner of the group
    address public  owner;

    // Track of balances
    mapping (address => uint256 ) public balances;
    // Nested mapping: debts[from][to] = amount owed
    mapping(address => mapping(address => uint256)) public debts;
    // Registered friends
    address[] public friends;
    mapping (address => bool) public isRegistered;

    constructor (){
        owner = msg.sender;
        friends.push(msg.sender);
        isRegistered[msg.sender] = true; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action!");
        _;
    }
    modifier onlyRegistered() {
        require(isRegistered[msg.sender], "User not registered");
        _;
    }

    // Register friend to group
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!isRegistered[_friend], "Friend already registered");
        
        isRegistered[_friend] = true;
        friends.push(_friend);
    }
    
    // Check balance
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }

    // Add funds to balance
    function deposit() public payable onlyRegistered {
        require(msg.value > 0, "User must send ETH");
        balances[msg.sender] += msg.value;
    }
    // Withdraw of balance
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "The balance is insufficient");
        balances[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    // Transfer funds
    function transfer(address payable _destinatary, uint256 _amount) public onlyRegistered {
        require(_destinatary != address(0), "Invalid address");
        require(isRegistered[_destinatary], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        _destinatary.transfer(_amount);
        balances[_destinatary]+=_amount;
    }

    // Record new debts to group
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(isRegistered[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        debts[_debtor][msg.sender] += _amount;
    }

    // Pays the debts  from the balcen on wallet
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(isRegistered[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");    
        // Update balances and debt
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

}