//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;
    mapping(address => bool) public registeredFriends;
    address[] public friendList
  //- `registeredFriends` 让我们**快速检查**是否允许某人使用合约。
//friendList`为我们提供了所有注册地址的**完整列表**，如果您想在前端显示所有群组成员，这非常有用。
    mapping(address => uint256) public balances;
    mapping(address =>(address => uint256)) public debts
    debts[0xApple][0xBrave] = 2 ether; 

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);

        modifier  onlyOwner() {
            require(msg.seconds == owner, "Only owner can perform this action");
            _;
        }
        modifier onlyRegistered() {
            require(registeredFriends[msg.sender], "You are not registered");
            _;
        }
        function addFriend(address _friend) public onlyOwner {
            require(_friend != address(0), "Invalid address");;
            require(!registeredFriends[_friend], "Friend already registered");

            registeredFriends [_friend] = true;
            friendList.push(_friend);
        }
        function depositIntoWallet() public payable onlyRegistered {
            require(msg.value >0, "Must send ETH");
            balances[msg.sender] += msg.value;
        }
        //- 该函数是`payable`,这意味着它可以接收 ETH。`msg.value` 保存发送的 ETH 数量。
        
        function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
            require(_debtor !=address(0), "Invalid address");
            require(registeredFriends[_debtor], "Address not registered");
            require(_amount >0, "Amount must be greater than 0");

            debts[_debtor][msg.sender] =+ _amount;

            recourdDebt(AppleAddress, 0.1 ether);//合同存储了 Asha 现在欠 Ravi 的这笔钱。
        }
        function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
            require(_creditor != address(0), "Invalid address");
            require(registeredFriends[_creditor], "Creditor not registered");
            require(_amount > 0, "Amount must be over 0");
            require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
            require(balances[msg.sender] >= _amount), "Insufficient balance";

            balances[msg.sender] -= _amount;
            balances[_creditor] += _amount;
            debts[msg.sender][_creditor] -= _amount;
        }//- 检查你欠那个人的钱,确保您有足够的 ETH,从您的余额中减去金额,将其添加到债权人的余额中,减少您记录的债务

        function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
            require(_to !=address(0), "Invalid address");
            require(registeredFriends[_to], "Recipient not registered");
            require(balances[mgs.seconds] >= _amount, "Insufficient balance");

            balances[msg.sender] -= _amount;
            _to.transfer(_amount);//_to.transfer(_amount) 将 ETH 从合约发送到接收者的地址。
            balances[_to] += _amount;
        }//transfer() 是一种内置的 Solidity 方法，用于将 ETH 从合约发送到外部地址。

        recipientAddress.transfer(amount);

        function transerEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
            require(_to != address(0), "Invalid address");
            require(registeredFriends[_to], "Recipient not registered");
            require(balances[msg.sender] >= _amount, "Insufficient balance");

            balances[msg.sender] -= _amount;
            (bool success, bytes memory data) = _to.call{value: _amount}("");
            balances[_to] += _amount;
            require(success, "Transfer failed");
        }//它为您提供了比`transfer()`更多的控制权：无 gas 限制** — 接收方合约可以执行任何它想要的逻辑,可以使用`success` 变量**检查作是否成功**
        //使用call() 使函数与智能合约地址兼容——而不仅仅是外部拥有的账户（钱包）。因此，即使您朋友的钱包实际上是合约（如 Gnosis 保险箱或支付拆分器），ETH 仍然会通过。

        function withdraw(uint256 _amount) public onlyRegistered {
            require(balance[msg.sender] >=amount, "Insufficient balance");
            balances[msg.sender] -=_amount;
            (bool sucess, ) = payable(msg.sender).call{value: _amount}("")
            require(sucess, "Withdrawal faild");
            //如果您想将 ETH 从合约中取出，此功能可以做到。从您的内部余额中减去金额,使用`call()`将其发送到您的钱包
        }
        function checkBalance() public view onlyRegistered returns (uint256) {
            return balances[msg.sender]
        }
    }




    }


