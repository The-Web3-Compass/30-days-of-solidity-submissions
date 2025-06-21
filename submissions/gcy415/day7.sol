// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleIOU{
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;
    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;  // Owner is registered as friend
        friendList.push(msg.sender);
    }   
    modifier onlyOwner(){
        require(msg.sender == owner, "Only the owner can do this!");
        _;
    }
    modifier onlyRegistered(){
        require(registeredFriends[msg.sender], "You are not registered as friend");
        _;
    }
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address!");
        require(!registeredFriends[_friend],"This account already registered as friend");

        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }
    
    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }
    function recordDebts(address _debtor, uint256 _amount) public onlyRegistered{
        require(_debtor != address(0), "Invalid address!");
        require(registeredFriends[_debtor],"This account is not registered as friend");
        require(_amount > 0,"Amount must larger than zero");
        debts[_debtor][msg.sender] += _amount;
    }
    
    function payFromWallet(address _ceditor, uint256 _amount) public onlyRegistered{
        require(_ceditor != address(0), "Invalid address!");
        require(registeredFriends[_ceditor],"This account is not registered as friend");
        require(_amount > 0, "Amount must be larger than zero");
        require(debts[msg.sender][_ceditor] >= _amount,"Debt amount incorrect");
        require(balances[msg.sender]>= _amount,"Insufficient funds in wallet!");
        balances[msg.sender] -= _amount;
        balances[_ceditor] += _amount;
        debts[msg.sender][_ceditor] -= _amount;

    }

    function transferEther(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to != address(0),"Invalid address!");
        require(registeredFriends[_to],"This account is not registered as friend");
        require(balances[msg.sender]>= _amount, "Insufficient funds in wallet");
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;
    }

    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to != address(0),"Invalid address!");
        require(registeredFriends[_to],"This account is not registered as friend");
        require(balances[msg.sender]>= _amount, "Insufficient funds in wallet");
        balances[msg.sender] -= _amount;
        (bool success, ) = _to.call{value:_amount}("");
        balances[_to] += _amount;
        require(success, "Transfer failed");
    }

    function withdraw(uint256 _amount) public onlyRegistered{
        require(balances[msg.sender] >= _amount,"Insufficient funds in wallet!");

        balances[msg.sender] -= _amount;

        (bool success,) = payable(msg.sender).call{value:_amount}("");
        require(success, "Transfer failed");
    }
    
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
}