// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;    

contract SimpleIOUApp {
    // 链上群账
    // 跟踪债务，
    // 将 ETH 存储在他们自己的应用内余额中，
    // 并且可以轻松安顿下来，无需做数学或电子表格。

    address public owner;

    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public debts;
    // debts[debtor][creditor] = amount;  debtor欠creditor amount

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender==owner, "Only OWNER can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not REGISTERED");
        _;
    }

    function addFriend(address _friend) public onlyOwner() {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    function depositIntoWallet() public payable onlyRegistered() {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered() {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must greater than 0");

        debts[_debtor][msg.sender] += _amount;
    }
    // Ravi 调用 recordDebt(AshaAddress, 0.5 ether) 即 Asha欠Ravi 0.5 ETH

    function payFormWallet(address _creditor, uint256 _amount) public onlyRegistered() {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

    function transferEther(address payable _to, uint256 _amount) public onlyRegistered() {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount);  
        // transfer() 是内置的 Solidity 方法，用于将 ETH 从合约发送到外部地址
        // transfer() 可以将 ETH 发送到 钱包，但在处理合约时存在风险或限制
        balances[_to] += _amount;
    }
    
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        // call() 是 Solidity 中的一个低级函数，用于发送 ETH 和调用函数
        // 无 gas 限制，可以使用success 变量检查作是否成功
        balances[_to] += _amount;
        require(success, "Transfer failed");
    }

    function withdraw(uint256 _amount) public onlyRegistered() {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    function checkBalance() public view onlyRegistered() returns (uint256) {
        return balances[msg.sender];
    }
}