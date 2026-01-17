//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    mapping(address => mapping(address => uint256)) public debts;
    constructor(){
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }
    modifier onlyRegistered(){
        require(registeredFriends[msg.sender], "you are not registered");
        _;
    }
    function addFriend(address _firend) public onlyOwner{
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_address], "Friend already registered");
        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH.");
        balences[msg.sender] += msg.value;
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered{
        require(_debtor != address(0), "Invalid address");
        require(registeredFriend[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address.");
        require(registeredFriends[_creditor], "Creditor not registered.");
        require(_amount > 0, "amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balence.");
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -=amount;
    }

    function transferEtherViacall(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balences[msg.sender] -=amount;
        (bool success, ) = _to.call{value: _amount}("");
        balences[_to] += _amount;
        require(success,"Transfer failed");
        
    }
    function withdraw(uint256 _amount) public onlyRegistered{
        require(balences[msg.sender] >= amount, "Insufficient balence");
        balences[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "withdraw failed");
    }

    function checkBalence() public view onlyRegistered returns(uint256){
        return balences[msg.sender];
    }
}
