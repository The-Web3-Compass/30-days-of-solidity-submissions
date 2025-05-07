// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SimpleIOU {
    address public owner;
    address[] public users;
    mapping(address => uint256) userBalance;
    mapping(address => bool) registeredUsers;
    mapping(address => mapping(address => uint256)) debts; //debtor > creditor > amount

    constructor() {
        owner = msg.sender;
        registeredUsers[msg.sender] = true;
        users.push(msg.sender);
    }

    modifier isRegistered() {
        require(registeredUsers[msg.sender] == true, "not registered");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    function addUser(address _newUser) public onlyOwner {
        require(_newUser != address(0), "invalid address");
        require(_newUser != msg.sender, "owner is already registered");
        require(!registeredUsers[_newUser], "already registered");

        registeredUsers[_newUser] = true;
        users.push(_newUser);
        userBalance[_newUser] = 0;
    }

    function depositEther() external payable isRegistered {
        require(msg.value > 0, "Invalid amount");

        userBalance[msg.sender] += msg.value;
    }

    function recordDebt(uint _amount, address _debtor) external isRegistered {
        require(_amount > 0, "Invalid amount");
        require(userBalance[msg.sender] >= _amount, "Insufficient balance");
        require(_debtor != address(0), "invalid debtor address");
        require(registeredUsers[_debtor], "debtor isnt registered");

        debts[_debtor][msg.sender] += _amount;
    }

    function payCreditor(
        address _creditor,
        uint256 _amount
    ) public isRegistered {
        require(_creditor != address(0), "invalid creditor address");
        require(userBalance[msg.sender] >= _amount, "gareeb");
        require(registeredUsers[_creditor], "creditor isnt registered");
        require(debts[msg.sender][_creditor] >= _amount, "udhar kam hai isse");

        userBalance[_creditor] += _amount;
        userBalance[msg.sender] -= _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

    function transferEther(
        address payable _to,
        uint256 _amount
    ) public isRegistered {
        require(_amount > 0, "Invalid amount");
        require(_to != address(0), "invalid to address");
        require(registeredUsers[_to], "to isnt registered");
        require(userBalance[msg.sender] >= _amount, "gareeb");

        userBalance[msg.sender] -= _amount;
        _to.transfer(_amount);
    }

    function transferViaCall(
        address payable _to,
        uint256 _amount
    ) public isRegistered {
        require(_amount > 0, "Invalid amount");
        require(_to != address(0), "invalid to address");
        require(registeredUsers[_to], "to isnt registered");
        require(userBalance[msg.sender] >= _amount, "gareeb");

        userBalance[msg.sender] -= _amount;
        (bool success, ) = _to.call{value: _amount}("");

        require(success, "transaction failed");
    }

    function withdraw(uint256 _amount) public isRegistered {
        require(_amount > 0, "Invalid amount");
        require(userBalance[msg.sender] >= _amount, "gareeb");

        userBalance[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value : _amount}("");
        require(success, "transaction failed");
    }

    function getBalance() public view isRegistered() returns(uint256){
        return userBalance[msg.sender];
    }

    function getDebt(
        address _creditor
    ) public view isRegistered returns (uint256) {
        require(registeredUsers[_creditor], "creditor isnt registered");
        require(_creditor != address(0), "invalid address");

        return debts[msg.sender][_creditor];
    }
}
