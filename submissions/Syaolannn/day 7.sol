//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;

    //Track registered friends
    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    //Track balances
    mapping(address => uint256) public balances;

    //Simple debt tracking
    mapping(address => mapping(address => uint256)) public debt; // debtor -> creditor -> amount;
    
    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyRegistered(){
        require(registeredFriends[msg.sender], "You are not registeres");
        _;
    }

    //Register a new friend
    function addFriend(address _friend) public onlyOwner{
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    //Deposit funds to your balance
    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] +=msg.value;
    }

    //Record that someone owes you money
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered{
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater that 0");

        debt[_debtor][msg.sender] += _amount;
    }

    //Pay off debt using internal balance transfer
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered{
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount >0, "Amount must be greater than 0");
        require(debt[msg.sender][_creditor] >=_amount, "Debt amount incorrect");
        require(balances[msg.sender] >=_amount, "Insufficient balance");

        //Update balances and debt
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debt[msg.sender][_creditor] -=_amount;
    }

    //Direct transfer method using transfer()
    function transferEnter(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to !=address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount,  "Insuffient balance");
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to]+=_amount;
    }

    //Alternative transfer method using call()
    function transferEnterViaCall(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to !=address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >=_amount,  "Insuffient balance");
        
        balances[msg.sender] -= _amount;

        (bool success, ) =_to.call{value:_amount}("");
        balances[_to]+=_amount;
        require(success, "Transfer failed");
    }

    //Withfraw your balance
    function withdraw(uint256 _amount) public onlyRegistered{
        require(balances[msg.sender] >=_amount, "Insufficient balance");

        balances[msg.sender] -=_amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    //Check your balance
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
}