// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIou{
    address public owner;
    mapping (address => bool) public registeredFriends;
    address[] public friendlist;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;

    constructor(){
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendlist.push(msg.sender);
    } 

    modifier onlyOwner(){
        require(msg.sender == owner,"only owner can perform this action");
        _;
    }

    modifier onlyRegistered(){
        require(registeredFriends[msg.sender],"you are not registered");
        _;
    }
    //添加人进群组
    function addFriend(address _friend)public onlyOwner{
        require(_friend != address(0),"invalid address");
        require(!registeredFriends[_friend],"friend already registered");

        registeredFriends[_friend] =true;
        friendlist.push(_friend);
    }
    //存钱
    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value > 0,"must send ETH");
        balances[msg.sender] += msg.value;
    }
    //记录欠款
    function recordDebt(address _debtor,uint256 _amount) public onlyRegistered{
        require(_debtor != address(0),"invalid address");
        require(_amount > 0,"amount must be greater than 0");
        require(registeredFriends[_debtor],"address not registered");

        debts[_debtor][msg.sender] +=_amount;
    }
    //还钱：欠款人主动向借款人发起还款（数值）
    function payFromWallet(address _creditor,uint256 _amount) public onlyRegistered{
        require(_creditor != address(0),"invalid address");
        require(_amount > 0,"amount must be greater than 0");
        require(registeredFriends[_creditor],"creditor not registered");
        require(balances[msg.sender] >=_amount,"insufficient balance");
        require(debts[msg.sender][_creditor] >=_amount,"debt amount incorrect");

        balances[msg.sender] -=_amount;
        balances[_creditor] +=_amount;
        debts[msg.sender][_creditor] -=_amount;
    }
    //转钱（ether）2300gas transfer 允许您将 ETH 直接从合约发送到他们的钱包。
    function transferEther(address payable _to,uint256 _amount) public onlyRegistered{
        require(_to !=address(0),"invalid address");
        require(registeredFriends[_to],"recipient not registered");
        require(balances[msg.sender] >=_amount,"insufficient balance");

        balances[msg.sender] -=_amount;
        _to.transfer(_amount);
        balances[_to] +=_amount;
    }
    //转钱（ether） call  使函数与智能合约地址兼容——而不仅仅是外部拥有的账户（钱包）
    function transferEtherViacall (address payable _to,uint256 _amount) public onlyRegistered{
        require(_to !=address(0),"invalid address");
        require(registeredFriends[_to],"recipient not registered");
        require(balances[msg.sender] >=_amount,"insufficient balance");

        balances[msg.sender] -=_amount;
        (bool success,) = _to.call{value: _amount}("");
        balances[_to] +=_amount;
        require(success,"transfer failed");
    }

    //取钱
    function withdraw(uint256 _amount) public onlyRegistered{
        require(balances[msg.sender] >= _amount,"insufficient balance");

        balances[msg.sender] -=_amount;
        (bool success,)=payable(msg.sender).call{value: _amount}("");
        require(success,"withdraw failed");
    }

    function checkbalance() public view onlyRegistered returns(uint256){
        return balances[msg.sender];
    }

}

//onwer:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 1:0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 2:0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
