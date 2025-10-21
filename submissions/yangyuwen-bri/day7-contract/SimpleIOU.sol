// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SimpleIOU{

    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts; //debts[debtor][creditor] = amount;

    constructor(){
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only the owner can call this function.");
        _;
    }

    modifier onlyRegistered(){
        require(registeredFriends[msg.sender], "you are not registered.");
        _;
    }

    function addFriends(address _friend) public onlyOwner{
        require(_friend != address(0), "invalid address.");
        require(!registeredFriends[_friend], "friends has already been registered.");
        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value > 0, "invalid deposit amount.");
        balances[msg.sender] += msg.value;
    }

    function checkBalance() public view onlyRegistered returns(uint256){
        return(balances[msg.sender]);
    }

    function recordDebts(address _debtor, uint256 _amount) public onlyRegistered{
        require(_amount > 0, "invalid amount.");
        require(registeredFriends[_debtor], "not a registered friend.");
        require(_debtor != address(0), "invalid address");

        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor, uint _amount) public onlyRegistered{
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

    //transferEther
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered{
        
        require(_to != address(0), "invalid address.");
        require(registeredFriends[_to], "recipient not registered.");
        require(balances[msg.sender] >= _amount, "insufficient balance.");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount); //sends ETH from the contract to the recipient's address.
        balances[_to] += _amount;

    }
    //call()
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered{

        require(_to != address(0), "invalid address.");
        require(registeredFriends[_to], "recipient not registered.");
        require(balances[msg.sender] >= _amount, "insufficient balance.");

        balances[msg.sender] -= _amount;

        (bool success, ) = _to.call{value:_amount}(""); //No gas limit
        balances[_to] += _amount;
        require(success, "transfer failed.");

    }

    function withdraw(uint256 _amount) public onlyRegistered{
        require(balances[msg.sender] >= _amount, "insufficient balance.");

        balances[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "withdraw failed.");
    }

}