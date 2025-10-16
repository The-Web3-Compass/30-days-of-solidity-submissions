//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleIOU{

    address public owner;     //标记谁是合约主人
    mapping(address => uint256) public balance;      //存放每个用户在合约中的钱包余额
    mapping(address => bool) public registeredFriends;     //判断一个地址是否是注册过的“好友”
    address[] public friendList;      //存所有已注册好友的地址列表

    mapping(address => mapping(address => uint256)) public debts;     //谁欠谁多少钱

    constructor() {
        owner = msg.sender;      //将部署者设置为合约的拥有者
        registeredFriends[msg.sender] = true;     //部署合约的人自动成为第一个注册的用户
        friendList.push(msg.sender);      //把部署者的地址加入好友列表
    }

    modifier onlyOwner() {      //创建一个“仅限所有者执行”的限制规则
        require(msg.sender == owner, "Only owner can perform this action");      //只有当调用者是owner，函数才能进行，否则退回并弹出“”
        _;
    }

    modifier onlyRegistered() {      //只允许注册用户执行特定函数
        require(registeredFriends[msg.sender], "You are not registered");      //未注册用户调用时会被拒绝，否则退回并弹出“”
        _;
    }

    function addFriend(address _friend) public onlyOwner {      //允许合约所有者添加新好友
        require(_friend != address(0), "Invalid address");     // 防止错误添加空地址
        require(!registeredFriends[_friend], "Friend already registered");      //防止重复注册

        registeredFriends[_friend] = true;     //将好友加入系统
        friendList.push(_friend);      //更新好友列表
    }

    function depositIntoWallet() public payable onlyRegistered {      //允许注册用户往合约里存钱
        require(msg.value >0, "Must send ETH");      //防止发送 0 ETH
        balance[msg.sender] += msg.value;      //将转入的 ETH 金额计入调用者的内部余额
    }

function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {      //记录“谁欠我多少钱”
//检查地址是否有效，对方已经注册，欠款金额大于0
    require(_debtor != address(0), "Invalid address");
    require(registeredFriends[_debtor], "Address not registered");
    require(_amount > 0, "Amount must be greater than 0");

    debts[_debtor][msg.sender] += _amount;     //增加债务记录
}

function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {     //用内部钱包余额偿还债务
    require(_creditor != address(0), "Invalid address");      //地址有效
    require(registeredFriends[_creditor], "Creditor not registered");      //对方是注册用户
    require(_amount > 0, "Amount must be greater than 0");      //金额大于 0
    require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");      //确实有这么多欠款
    require(balance[msg.sender] >= _amount, "Insufficient balance");      //自己余额足够

    balance[msg.sender] -= _amount;      //从债务人余额扣除偿还金额
    balance[_creditor] += _amount;      //给债权人增加相应金额（内部记账）
    debts[msg.sender][_creditor] -= _amount;      //从债务记录中减掉已偿还金额
}

function transferEther(address payable _to, uint256 _amount)public onlyRegistered {     //定义直接 ETH 转账函数
     require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;      //扣除发送方余额
        _to.transfer(_amount);      //如果失败，自动回滚交易
    }

function transferEtherViaCall(address payable _to,uint256 _amount) public onlyRegistered {      //定义另一种转账方式，使用call,call是低级转账函数，安全性高但更复杂
    require(_to != address(0), "Invalid address");
    require(registeredFriends[_to], "Recipient not registered");
    require(balance[msg.sender] >= _amount, "Insufficient balance");
    
    balance[msg.sender] -= _amount;      //扣除发送方余额

    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Transfer Failed");     //检查转账是否成功，否则回滚
}

function withdraw(uint256 _amount) public onlyRegistered {      //定义提现函数,用户从合约提取 ETH 到自己的钱包
    require(balance[msg.sender] >= _amount, "Insufficient balance");      //检查余额是否足够

    balance[msg.sender] -= _amount;      //扣除发送方余额

    (bool success, ) = payable(msg.sender).call{value: _amount}("");      //向调用者的钱包发送 ETH
    require(success, "Withdrawal failed");      //如果转账失败，回滚交易
}

function checkBalance() public view onlyRegistered returns (uint256) {      //定义查询余额函数
    return balance[msg.sender];      //返回调用者的内部余额
}

}