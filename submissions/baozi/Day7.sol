// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    address public owner;

    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public debts; // debtor => creditor => amount

    event FriendAdded(address indexed friend);
    event Deposit(address indexed from, uint256 amount);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtPaid(address indexed from, address indexed to, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event TransferMade(address indexed from, address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        registeredFriends[_friend] = true;
        friendList.push(_friend);

        emit FriendAdded(_friend);
    }

    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Debtor not registered");
        require(_amount > 0, "Amount must be greater than 0");

        debts[_debtor][msg.sender] += _amount;

        emit DebtRecorded(_debtor, msg.sender, _amount);
    }

    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;

        emit DebtPaid(msg.sender, _creditor, _amount);
    }

    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount); // ✅ 不加 balances[_to] += _amount

        emit TransferMade(msg.sender, _to, _amount);
    }

    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");

        emit TransferMade(msg.sender, _to, _amount);
    }

    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, _amount);
    }

    function checkBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function getFriendList() public view returns (address[] memory) {
        return friendList;
    }

    receive() external payable {
        revert("Use depositIntoWallet to send ETH");
    }

    fallback() external payable {
        revert("Fallback not supported");
    }
}
