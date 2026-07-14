//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {

    address public owner;
    address[] public friends;
    mapping(address => bool) public registeredFriends;
    mapping(address => uint256) private balance;
    mapping(address => mapping(address => uint256)) private debts;

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friends.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyRegisteredFriends() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    function checkAddressValid(address _address) internal {
        require(address(0) != _address, "Invalid address");
    }

    function addFriend(address _friend) public onlyOwner {
        checkAddressValid(_friend);
        require(_friend != owner, "Owner has already registered");
        require(!registeredFriends[_friend], "Friend has already registered");

        friends.push(_friend);
        registeredFriends[_friend] = true;
    }

    function depositeIntoWallet() public payable onlyRegisteredFriends {
        require(msg.value > 0, "Must send ETH");

        balance[msg.sender] += msg.value;
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegisteredFriends {
        checkAddressValid(_debtor);
        require(registeredFriends[_debtor], "Debtor not registered");
        require(_amount > 0, "Amount should be greater than 0");

        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor, uint256 _amount) public onlyRegisteredFriends {
        checkAddressValid(_creditor);
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount should be greater than 0");
        require(_amount <= debts[msg.sender][_creditor], "Debt amount incorrect");
        require(_amount <= balance[msg.sender], "Insufficient balance");

        debts[msg.sender][_creditor] -= _amount;
        balance[msg.sender] -= _amount;
        balance[_creditor] += _amount;
    }

    function transferEther(address payable _to, uint256 _amount) public onlyRegisteredFriends {
        checkAddressValid(_to);
        require(registeredFriends[_to], "Recepient not registered");
        require(_amount > 0, "Amount should be greater than 0");
        require(_amount <= balance[msg.sender], "Insufficient balance");

        balance[msg.sender] -= _amount;
        //A built-in Solidity method used to send ETH from a contract to an external address,
        //it's fine for sending ETH to wallets, but risky or limiting when dealing with contracts
        _to.transfer(_amount); 
        balance[_to] += _amount;
    }

    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegisteredFriends {
        checkAddressValid(_to);
        require(registeredFriends[_to], "Recepient not registered");
        require(_amount > 0, "Amount should be greater than 0");
        require(_amount <= balance[msg.sender], "Insufficient balance");

        //A low-level function in Solidity used for sending ETH and calling functions,
        //it's compatible with smart contract addresses
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
    }

    function withdraw(uint256 _amount) public onlyRegisteredFriends {
        require(_amount > 0, "Amount should be greater than 0");
        require(_amount <= balance[msg.sender], "Insufficient balance");

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
        balance[msg.sender] -= _amount;
    }

    function checkBalance() public view onlyRegisteredFriends returns(uint256) {
        return balance[msg.sender];
    }

}