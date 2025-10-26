// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract simpleIOU{
    address owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    mapping(address => uint256)balances;
    mapping(address => mapping(address => uint256))debts;

    constructor(){
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can perform this action");
        _;
    }

    modifier onlyregistered(){
        require(registeredFriends[msg.sender],"Only registered user can perform this action");
        _;
    }

    function addFriend(address _friend)public onlyOwner{
        require(_friend!=address(0),"Invalid address");
        require(_friend!=owner,"Cannot add owner");

        registeredFriends[_friend] = true;
        friendList.push(_friend);
    }

    function depositIntoWallet() public payable onlyregistered{
        require(msg.value>0,"Amount should greater than 0");
        balances[msg.sender] += msg.value;
    }

    function checkBalance()public view onlyregistered returns(uint256){
        return balances[msg.sender];
    }

    function recordDebt(address _debtor,uint256 _amount)public onlyregistered{
        require(_debtor != address(0),"Invalid address");
        require(registeredFriends[_debtor],"Debtor is not register");
        require(_amount>0,"amount should be greater than 0");

        debts[_debtor][msg.sender]+=_amount;
    }


    function tranferEther(address payable _to,uint256 _amount)public onlyregistered{
        require(_to!=address(0),"Invalid address");
        require(_amount>0,"amount should be greater than 0");

        //transfer/send:专门为 “转账 ETH” 设计的简化方法
        _to.transfer(_amount);
    }

    function transferEtherViaCall(address payable _to,uint256 _amount)public onlyregistered{
        require(_to!=address(0),"Invalid address");
        require(_amount>0,"amount should be greater than 0");

        //call 的本质不是 “ETH 转账工具”，而是 Solidity 提供的底层合约交互方法
        //它的核心能力是调用任意地址的函数（包括空函数），而传ETH”只是它的附加功能（通过 {value: ...} 指定）
        //传 ETH 的关键：{value: _amount} 这部分是 “给这次调用附加 ETH” 的语法，官方叫 “call 选项（call options）
        //在 call 和括号之间，用 {key: value} 的形式指定附加参数，目前支持 value（传 ETH）和 gas（指定本次调用的 gas 上限）
        //作用：告诉以太坊 “本次向 _to 发起调用时，同时转过去 _amount 数量的 ETH（单位是 Wei）”
        //("")这部分是 “函数调用的参数”但这里用空字符串 ""，是因为我们的需求是 “单纯转账”，不需要调用 _to 地址的任何函数
        (bool success,)=_to.call{value:_amount}("");

        require(success,"Transfer failed");
    }

    function payForDebts(address payable _creditor,uint256 _amount)public onlyregistered{
        require(_creditor != address(0),"Invalid address");
        require( registeredFriends[_creditor],"Debtor is not register");
        require(_amount>0,"Amount should be greater than 0");
        require(_amount<=debts[msg.sender][_creditor],"Amount is more than your debts");
        require(_amount<=balances[msg.sender],"Insufficient balance to transfer");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;

        
        tranferEther(_creditor, _amount);
    }

    function withdraw(uint256 _amount)public onlyregistered{
        require(_amount>0,"amount should be greater than 0");
        require(_amount<=balances[msg.sender],"Insufficient balance for withdrawal");

        balances[msg.sender] -= _amount;
        transferEtherViaCall(payable(msg.sender), _amount);
    }


}