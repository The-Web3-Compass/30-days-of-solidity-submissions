//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    // 我和朋友出去吃饭，我付的钱，我是owner，有自己的账户，我朋友欠我需要aa的钱
    address public owner;
    
    // 我又很多朋友，这里有注册的朋友，也有朋友列表，同样是一个array一个map
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    
    // 代表每个人的不同账户余额
    mapping(address => uint256) public balances;
    
    // 映射的映射，类似于x轴和y轴组成的坐标轴中的点为（x，y）
    // debts[debtor][creditor] = amount;
    mapping(address => mapping(address => uint256)) public debts; // debtor -> creditor -> amount
    
    // 这里为什么增加了注册朋友的初始化表示自己是自己的朋友
    constructor() {
        owner = msg.sender;
        // 自己是自己的朋友
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
    
    // 同样新增朋友
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");
        
        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }
    
    // 在我的钱包里存钱
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }
    
    // Record that someone owes you money
    // 记账，某个人欠自己多少钱
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        debts[_debtor][msg.sender] += _amount;
    }
    
    // Pay off debt using internal balance transfer
    // 当自己欠别人钱时，付费给别人
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // Update balances and debt
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }
    
    // Direct transfer method using transfer()
    // 不一定欠钱也可以转账，只是上一个函数需要消除欠款
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to]+=_amount;
    }
    
    // Alternative transfer method using call()
    // transfer的另一种方法，可以看到success
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;

        // 给_to这个地址传amount的价值
        (bool success, ) = _to.call{value: _amount}("");
        balances[_to]+=_amount;
        // 最后会判断是否成功
        require(success, "Transfer failed");
    }
    
    // Withdraw your balance
    // 我自己理解下来就是余额是在blockchain上的，而不是我真正余额里面的
    // payable只作用于地址，而不是amount，这个函数的input没有地址，所以可以把他payable化。
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
    
    // Check your balance
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
}

// owner：0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 
// address 1：0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 
// address 2：0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

// Day07
// 1. 在owner的账户下点击部署，并初始化array和map
// 2. 增加address1为friend，在列表中
// 3. 记录friend欠自己的钱，写入其地址和金额，记录debts
// 4. 切换到address1账户下，充值金额（payable），写入owner地址和还钱金额，debts会一起更新
// 5. debts只是用来记账，可以使用transfer或call函数直接转账即可