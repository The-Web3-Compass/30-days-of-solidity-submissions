//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendGroup;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public debts; 

       constructor() {
        owner = msg.sender;
        friendGroup.push(msg.sender);
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Administrative Privilege");
        _;
    }
    
    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You have not registered");
        _;
    }

    function addFriend(address newfriend) public onlyOwner {
        require(newfriend != address(0), "Invalid address");
        require(!registeredFriends[newfriend], "Friend already registered");
        registeredFriends[newfriend] = true;
        friendGroup.push(newfriend);
    }
    
    function depositAmount() public payable onlyRegistered {
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }

    function recordDebt(address debtor, uint256 debtAmount) public onlyRegistered {
        require(debtor != address(0), "Invalid address");
        require(registeredFriends[debtor], "Debtor have not registered");
        require(debtAmount > 0, "Amount must be greater than 0");
        debts[debtor][msg.sender] += debtAmount;
     }
    
    function payFromWallet(address creditor, uint256 returnDebtAmount) public onlyRegistered {
        require(creditor != address(0), "Invalid address");
        require(registeredFriends[creditor], "Creditor have not registered");
        require(returnDebtAmount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][creditor] >= returnDebtAmount, "Debt amount incorrect");
        require(balance[msg.sender] >= returnDebtAmount, "Insufficient balance");
        
        balance[msg.sender] -= returnDebtAmount;
        balance[creditor] += returnDebtAmount;
        debts[msg.sender][creditor] -= returnDebtAmount;
    }
    function transferEther(address payable recipient, uint256 transferAmount) public onlyRegistered {
        require(recipient != address(0), "Invalid address");
        require(registeredFriends[recipient], "Recipient have not registered");
        require(transferAmount > 0, "Amount must be greater than 0");
        require(balance[msg.sender] >= transferAmount, "Insufficient balance");

        balance[msg.sender] -= transferAmount;
        recipient.transfer(transferAmount);
        balance[recipient]+=transferAmount;
    }
    
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        
        balance[msg.sender] -= _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        balance[_to]+=_amount;
        require(success, "Transfer failed");
    }
    
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        
        balance[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
    
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balance[msg.sender];
    }
}
    