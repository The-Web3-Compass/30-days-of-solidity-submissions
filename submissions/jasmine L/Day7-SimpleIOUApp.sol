// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOUApp {
    address public owner;
    address[] public friends;
    mapping(address => bool) public Isfriends;

     
    mapping(address => uint256) public balances; // 记录余额

    //mapping(address => uint256) public debts;//欠钱
    mapping (address => mapping (address => uint256)) public debts;//欠钱(谁欠谁多少钱))
    // mapping(address => uint256) public retriDebts;//还钱

    constructor(){
        owner = msg.sender;
        Isfriends[msg.sender]=true;
        friends.push(msg.sender);
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier onlyFriends{
        require(Isfriends[msg.sender] , "Not the friend");
        _;
    }
    /* 大家一起存钱，初始化时每个人存的钱，根据每个人欠钱还钱做一个表格。但是始终这个钱还是在合约内部。
    - 存入 ETH
    - 记录债务，
    - 偿还债务，
    - 发送 ETH，
    - 或者撤回它。*/
    

    // 注册好友，只允许所有者用，她想给谁垫付给谁垫付
    function addFriend(address _add) public onlyOwner{
        require(_add!= address(0),"Invalid address");
        require(!Isfriends[_add], "Already friends");

        Isfriends[_add] = true;
        friends.push(_add);
    }

    // 充值到钱包
    function depositIntoWallet() public payable onlyFriends{
        require(msg.value > 0, "Invalid amount");
        balances[msg.sender] += msg.value;
    }

    // 记录欠款
    function recordDebt(address _debator, uint256 _amount) public onlyFriends{
        require(_debator!=address(0), "Invalid address");
        require(Isfriends[_debator],"Address not registered");
        require(_amount > 0,"Invalid amount");
        debts[_debator][msg.sender] += _amount;

    }

    // 用钱包还款，暂时只是记录没有真的还款
    // 实际上并没有 ETH 离开合约。它只是在用户的余额之间内部移动。
    function payFromWallet(address _creditor, uint256 _amount) public onlyFriends{
        require(_creditor!=address(0), "Invalid address");
        require(Isfriends[_creditor],"Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        //欠款数额不对，此处我们做的功能是如果预计还款多于欠款就失败
        require(debts[msg.sender][_creditor]>=_amount, "Debt amount incorrect");

        require(balances[msg.sender] >= _amount, "Insufficient balance");//钱包余额不足

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -=_amount;
    }

    // 直接转账还款：直接从合约中发送到他们的钱包（从合约中移除）
    function transferEther(address payable _to, uint256 _amount) public payable onlyFriends{
        require(_to != address(0), "Invalid address");
        require(Isfriends[_to],"Address not registered");

        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;       

    }

    // 查询余额
    function checkBalance() public view returns(uint256 ){
        return balances[msg.sender];
    }   

    // 从智能合约中提现
    function withdraw(uint256 _amount) public onlyFriends{
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        (bool success, ) = payable (msg.sender).call{value:_amount}("");
        require(success, "Withdrawal failed");

    }

    

}