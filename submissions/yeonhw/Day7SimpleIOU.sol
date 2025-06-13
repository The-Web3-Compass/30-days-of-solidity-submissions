// SPDX - License - Identifier : MIT
pragma solidity^0.8.0;

contract SimpleIOU{
    address public owner;  //确定小组管理员
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;  //嵌套映射
    // 例如 debts[0xAsha][0xRavi] = 1.5 ether; 意味着Asha 欠 Ravi 1.5 ETH

    constructor(){
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyRegistered(){
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    // 功能：
    // 将朋友添加到小组成员名单中
    function addFriend(address _friend) public onlyOwner{
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    //钱包
    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value; 
    }

    //记录债务(仅记录）
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered{
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "address not registered"); //要求欠债人是小组成员
        require(_amount > 0, "Amount must be greater than 0");

        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered{
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect"); //确保没有多说欠款
        require(balances[msg.sender] >= _amount, "Insufficient balance"); //确保这个欠款人钱包里的钱足够用来还钱

        balances[msg.sender] -= _amount;  //从欠款人账户中扣除还款金额
        balances[_creditor] += _amount;  //将还款金额加到债主钱包账户中
        debts[msg.sender][_creditor] -= _amount;  //从欠款记录中减去已经还过的部分
    }

    //使用transfer将ETH发送给另一个小组成员，但可能存在限制
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;
    }

    //使用call将ETH发送给另一个小组成员
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered{
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insuffient balance");

        balances[msg.sender] -= _amount;

        (bool success, ) = _to.call{value: _amount}("");
        balances[_to] += _amount;
        require(success, "Transfer failed");
    }

    //撤回
    function withdraw(uint256 _amount) public onlyRegistered{
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    //检查账户内的余额
    function checkBalance() public view onlyRegistered returns (uint256){
        return balances[msg.sender];
    }

}

