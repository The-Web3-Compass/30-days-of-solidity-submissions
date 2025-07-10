//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract SimpleIOU {
    address public owner;
    address[] friendList;
    mapping(address => bool) public registeredFriends;
    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) public debt; // nested mapping, debtor->creditor->amount

    constructor () {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Access Denied: Only the owner can perform this action.");
        _;
    }

    modifier onlyRegisteredFriends {
        require(registeredFriends[msg.sender],"You are not registered.");
        _;
    }

    // add a friend
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address.");
        require(!registeredFriends[_friend], "Already registered this friend");
        require(_friend != owner, "You can not add yourself as a friend.");
        friendList.push(_friend);
        registeredFriends[_friend] = true;
    }

    function depositIntoWallet() public payable onlyRegisteredFriends {
        require(msg.value > 0, "No amount of ether to deposit.");
        balance[msg.sender] += msg.value;
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegisteredFriends {
        require(_debtor != address(0), "Invalid debtor.");
        require(registeredFriends[_debtor], "The debtor is not registered.");
        require(_amount > 0, "No amount of Ether to record as a debt."); 
        debt[_debtor][msg.sender] = _amount;

    }

    function payFromWallet(address _creditor, uint256 _amount) public onlyRegisteredFriends {
        require(_creditor != address(0), "Invalid debtor.");
        require(registeredFriends[_creditor], "The creditor is not registered.");
        require(_amount > 0, "You have to pay some Ether.");
        require(balance[msg.sender] >= _amount, "You don't have enough Ether to pay for the debt.");
        require(debt[_creditor][msg.sender]>= _amount, "Debt amount is incorrect.");
        balance[msg.sender] -= _amount;
        balance[_creditor] += _amount;
        debt[msg.sender][_creditor]-= _amount;
    }

    function transferEther(address payable _to, uint256 _amount) public onlyRegisteredFriends {
        require(_to != address(0), "Invalid recipient.");
        require(registeredFriends[_to], "The recipient is not registered.");
        require(_amount > 0, "You don't have enough Ether to transfer.");
        require(balance[msg.sender] >= _amount, "Insufficient funds in your wallet");
        balance[msg.sender] -= _amount;
        _to.transfer(_amount); // transfer is a built-in function that sends Ether from one address to another address
    }

    function transferEtherViaCall(address payable _to, uint256 _amount)public onlyRegisteredFriends{
        require(_to != address(0), "Invalid recipient.");
        require(registeredFriends[_to], "The recipient is not registered.");
        require(_amount > 0, "You don't have enough Ether to transfer.");
        require(balance[msg.sender] >= _amount, "Insufficient funds in your wallet");
        balance[msg.sender] -= _amount;
        (bool success,) = _to.call{value:_amount}(""); // call is a low-level function to send Ether
        require(success, "Failed to transfer Ether via call"); // .call{} will not reverse when somthing goes wrong, so has to set a success flag
    }

    function withdraw(uint256 _amount) public onlyRegisteredFriends{
        require(balance[msg.sender] >= _amount, "Insufficient funds in your wallet");
        balance[msg.sender] -= _amount;
        (bool success,) = payable(msg.sender).call{value:_amount}(""); //?? has to be payable to receive Ether
        require(success, "Failed to withdraw.");
    }

    function checkBalance() public view onlyRegisteredFriends returns(uint256) {
        return balance[msg.sender];
    }
}
