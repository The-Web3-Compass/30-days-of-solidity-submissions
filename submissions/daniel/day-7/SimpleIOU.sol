// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

contract SimpleIOU {
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;

    constructor() {
        owner = msg.sender;
        registeredFriends[owner] = true;
        friendList.push(owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    function addFriend(address _friend) public onlyOwner {
        _requireValidAddress(_friend);
        require(!registeredFriends[_friend], "Friend already registered");
        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(registeredFriends[_debtor], "Debtor is not registered");
        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        _requireValidAddress(_creditor);
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        _prepareTransfer(_to, _amount);
        _to.transfer(_amount);
        balances[_to] += _amount;
    }

    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        _prepareTransfer(_to, _amount);

        (bool success,) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        balances[_to] += _amount;
    }

    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }

    function _prepareTransfer(address _to, uint256 _amount) internal {
        _requireValidAddress(_to);
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
    }

    function _requireValidAddress(address _user) internal pure {
        require(_user != address(0), "Invalid address");
    }
}
