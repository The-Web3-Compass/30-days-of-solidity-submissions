// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract SimpleIou {
    error Not__RegisteredFriend();
    error Invalid__Address();
    error NotEnough__Balance();

    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    mapping(address => uint256) public Balances;
    mapping(address => mapping(address => uint256)) public debts;

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredFriend() {
        require(registeredFriends[msg.sender], "You are not a registered ");
        _;
    }

    function registeredFriendsList(address _addFriend) public onlyOwner {
        if (_addFriend == address(0)) {
            revert Invalid__Address();
        }
        if (registeredFriends[_addFriend]) {
            revert Not__RegisteredFriend();
        }
        registeredFriends[_addFriend] = true;

        friendList.push(_addFriend);
    }

    function depositIntoWallet() public payable onlyRegisteredFriend {
        if (msg.value == 0) {
            revert NotEnough__Balance();
        }
        Balances[msg.sender] += msg.value;
    }

    function recordDebt(
        address _debtor,
        uint256 _amount
    ) public onlyRegisteredFriend {
        if (_debtor == address(0)) {
            revert Invalid__Address();
        }

        if (!registeredFriends[_debtor]) {
            revert Not__RegisteredFriend();
        }

        if (_amount == 0) {
            revert NotEnough__Balance();
        }
        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(
        address _creditor,
        uint256 _amount
    ) public onlyRegisteredFriend {
        if (_creditor == address(0)) {
            revert Invalid__Address();
        }
        if (!registeredFriends[_creditor]) {
            revert Not__RegisteredFriend();
        }
        if (_amount == 0) {
            revert NotEnough__Balance();
        }
        if (debts[msg.sender][_creditor] < _amount) {
            revert NotEnough__Balance();
        }
        if (Balances[msg.sender] < _amount) {
            revert NotEnough__Balance();
        }

        Balances[msg.sender] -= _amount; // Subtracts the payment amount from the sender's balance
        Balances[_creditor] += _amount; // Adds to the creditor's balance
        debts[msg.sender][_creditor] -= _amount; // Reduces the debt amount
    }

    function transferAmount(
        address payable _to,
        uint256 _amount
    ) public onlyRegisteredFriend {
        if (_to == address(0)) {
            revert Invalid__Address();
        }
        if (!registeredFriends[_to]) {
            revert Not__RegisteredFriend();
        }

        if (_amount == 0) {
            revert NotEnough__Balance();
        }
        if (Balances[msg.sender] < _amount) {
            revert NotEnough__Balance();
        }

        Balances[msg.sender] -= _amount; // Subtracts the transfer amount from the sender's balance
        Balances[_to] += _amount; // Adds to the recipient's balance
        (bool success, ) = _to.call{value: _amount}(""); // Transfer the amount to the recipient
        if (!success) {
            revert("Transfer failed"); // Revert if the transfer fails
        }
    }

    function withdraw(uint256 _amount) public onlyRegisteredFriend {
        if (_amount == 0) {
            revert NotEnough__Balance();
        }
        if (Balances[msg.sender] < _amount) {
            revert NotEnough__Balance();
        }

        Balances[msg.sender] -= _amount; // Subtracts the withdrawal amount from the sender's balance
        (bool success, ) = msg.sender.call{value: _amount}(""); // Transfer the amount to the sender
        if (!success) {
            revert("Withdrawal failed"); // Revert if the withdrawal fails
        }
    }

    function getBalance() public view onlyRegisteredFriend returns (uint256) {
        return Balances[msg.sender];
    }
}
