//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleIOU {
    address public owner; //所有者
    mapping(address => bool) public registerFriends;  //已注册好友
    address[] public friendList;  //好友列表

    mapping(address => uint256) public balances; //地址->余额
    mapping(address => mapping(address => uint256)) public debts; //地址->债务, debts[0xAsha][0xRavi] = 1.5 ether; 表示asha欠ravi 1.5eth

    constructor() {
        owner = msg.sender;
        registerFriends[msg.sender] = true;
        friendList.push(msg.sender);

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
        _;

    }

    modifier onlyRegistered() {
        require(registerFriends[msg.sender], "you are not registerd");
        _;
    }

    //添加朋友
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registerFriends[_friend], "friend already registered");

        registerFriends[_friend] = true;
        friendList.push(_friend);

    }

    //存款到钱包
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;

    }

    //记录债务
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registerFriends[_debtor], "Address not register");
        require(_amount > 0, "Amount must be greater than 0");

        debts[_debtor][msg.sender] += _amount;
    }


    //从钱包支付, 使用合约里的eth偿还某人
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registerFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;

    }

    //转我的钱给小伙伴
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid addresss");
        require(registerFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;


    }


    //使用call转账给小伙伴
    function transferViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid addresss");
        require(registerFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;

        (bool success,) = _to.call{value: _amount}("");
        balances[_to] += _amount;
        require(success, "transfer failed");

    }


    //将eth从合约中取出
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool success,)  = payable(msg.sender).call{value: _amount}("");
        require(success, "withdraw failed");

    }

    function chekcBanlance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];

    }


}