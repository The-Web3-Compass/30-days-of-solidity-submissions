// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract SimpleIOU{
    /**
    - Track debts,
    - Store ETH in their own in-app balance,
    - And settle up easily, without doing math or spreadsheets.
    */

    address public owner;

    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) public debts;

    constructor(){
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    // Only owner and register deposit ETH,record debts,pay debts,send ETH,withdraw
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    function addFriends(address _friend) public onlyOwner{
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");
        registeredFriends[_friend] = true;
        friendList.push(_friend);

    }

     
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }



    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value > 0,"Invalid amount");
        balances[msg.sender] = msg.value;

    }

    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;        

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }



    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered{
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Invalid Amount");
        debts[_debtor][msg.sender] += _amount;

    }


    function payFromWallet(address _creditor,uint256 _amount) public onlyRegistered{
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Invalid Amount");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;

    }

    
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
    
        balances[msg.sender] -= _amount;
    
        (bool success, ) = _to.call{value: _amount}("");
        balances[_to] += _amount;
        require(success, "Transfer failed");
}








}