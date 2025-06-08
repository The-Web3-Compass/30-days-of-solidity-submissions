//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public Owner;
    mapping(address => bool) public RegisteredFriends;
    address[] public FriendList;
    mapping(address => uint256) public Balances;
    mapping(address => mapping(address => uint256)) public Debts; 
    
    constructor() {
        Owner = msg.sender;
        RegisteredFriends[msg.sender] = true;
        FriendList.push(msg.sender);
    }
    
    modifier OnlyOwner() {
        require(msg.sender == Owner, "Only owner can perform this action");
        _;
    }
    
    modifier OnlyRegistered() {
        require(RegisteredFriends[msg.sender], "You are not registered");
        _;
    }
    
    function AddFriend(address _friend) public OnlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!RegisteredFriends[_friend], "Friend already registered");
        
        RegisteredFriends[_friend] = true;
        FriendList.push(_friend);
    }
 
    function DepositIntoWallet() public payable OnlyRegistered {
        require(msg.value > 0, "Must send ETH");
        Balances[msg.sender] += msg.value;
    }
    
    function RecordDebt(address _debtor, uint256 _amount) public OnlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(RegisteredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        Debts[_debtor][msg.sender] += _amount;
    }
    
    function PayFromWallet(address _creditor, uint256 _amount) public OnlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(RegisteredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(Debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(Balances[msg.sender] >= _amount, "Insufficient balance");
        
        Balances[msg.sender] -= _amount;
        Balances[_creditor] += _amount;
        Debts[msg.sender][_creditor] -= _amount;
    }
    
    function TransferEther(address payable _to, uint256 _amount) public OnlyRegistered {
        require(_to != address(0), "Invalid address");
        require(RegisteredFriends[_to], "Recipient not registered");
        require(Balances[msg.sender] >= _amount, "Insufficient balance");
        Balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        Balances[_to]+=_amount;
    }
    
    function TransferEtherViaCall(address payable _to, uint256 _amount) public OnlyRegistered {
        require(_to != address(0), "Invalid address");
        require(RegisteredFriends[_to], "Recipient not registered");
        require(Balances[msg.sender] >= _amount, "Insufficient balance");
        
        Balances[msg.sender] -= _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        Balances[_to]+=_amount;
        require(success, "Transfer failed");
    }
    
    function Withdraw(uint256 _amount) public OnlyRegistered {
        require(Balances[msg.sender] >= _amount, "Insufficient balance");
        
        Balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
    
    function CheckBalance() public view OnlyRegistered returns (uint256) {
        return Balances[msg.sender];
    }
}
