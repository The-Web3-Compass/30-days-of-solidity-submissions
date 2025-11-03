//SPDX-License-Identifier:MIT 
pragma solidity ^0.8.0;

contract SimpleIOU{
//前置准备
    //主理人
    address owner;
    //注册标记
    mapping(address=>bool) public registeredFriends;
    //人员清单
    address[] public friendList;
    //存钱
    mapping(address=>uint256)public balances;
    //借贷信息(使用嵌套映射
    mapping(address=>mapping(address=>uint256))public debts;

    //初始化（构造函数
    constructor(){
        owner=msg.sender;
        registeredFriends[msg.sender]=true;
        friendList.push(msg.sender);

    }

    //自动检查小警察（标识符
    modifier onlyOwner{
        require(msg.sender==owner,"only owner can perform this action.");
        _;
    }
    modifier onlyRegistered{
        require(registeredFriends[msg.sender],"you should register first.");
        _;
    }

//操作
    //添加成员
    function addFriends(address _friend) public onlyOwner{
        require(_friend !=address(0),"Invalid address.");
        require(!registeredFriends[_friend],"this friend has already added.");

        registeredFriends[_friend]=true;
        friendList.push(_friend);
    }

    //把钱转入合约，合约内账户+
    function depositIntoWallet()public payable onlyRegistered{
        require(msg.value>0,"must send ETH.");
        balances[msg.sender]+=msg.value;
        
    }

    //记录借贷情况
     //小组内借钱记录（债权人登记（合约内转账
    function recordDebt(address _debtor,uint256 _amount)public onlyRegistered{
        require(_debtor!=address(0),"Inavalid address.");
        require(_amount>0,"amount must be greater than zero.");
        require(registeredFriends[_debtor]==true,"address not registered.");
       // require(balances[_debtor]>=_amount,"debtor didn't have enough balance.");
       //为什么么这里不需要表明本人msg的余额大于amount

       debts[_debtor][msg.sender]+=_amount;

    }
    //还钱
    //小组内还钱（债务人登记(合约内部转账
    function payFromWallet(address _creditor,uint256 _amount) public onlyRegistered{
        require(_creditor!=address(0),"Invalid address.");
        require(_amount>0,"amount must be greater than zero.");
        require(registeredFriends[_creditor]==true,"address not registered.");
        require(debts[msg.sender][_creditor]>=_amount,"you didn't have enough debt.");
        require(balances[msg.sender]>=_amount,"you didn't have enough balance.");

        balances[msg.sender]-=_amount;
        balances[_creditor]+=_amount;
        debts[_creditor][msg.sender]-=_amount;

    }
    //直接转账（提现转给朋友
    function tranceferEther(address payable _to,uint _amount) public onlyRegistered{
        require(_to!=address(0),"Invalid address!");
        require(balances[msg.sender]>=_amount,"you didn't have enough balance.");
        require(_amount>0,"Invalid amount!");
        
        balances[msg.sender]-=_amount;
        //balances[_to]+=_amount;
        _to.transfer(_amount);
    }

    //通过call方式转账
    function tranceferEtherViaCall(address payable _to,uint256 _amount)public onlyRegistered{
        require(_to!=address(0),"Invalid address!");
        require(balances[msg.sender]>=_amount,"you didn't have enough balance.");
        require(_amount>0,"Invalid amount!");

        balances[msg.sender]-=_amount;
        (bool success,)=_to.call{value:_amount}("");
        require(success,"transfer failed.");
    }
    //提现
    function withdraw(uint256 _amount)public onlyRegistered{
        require(balances[msg.sender]>=_amount,"you didn't have enough money.");
        
        balances[msg.sender]-=_amount;
       // payable(msg.sender).transfer(_amount);
       //用call的方式
       (bool success,)=msg.sender.call{value:_amount}("");
       require(success,"withdraw failed.");
    }

    //显示余额
    function getBalance()public view onlyRegistered returns(uint256){
        return balances[msg.sender];
    }

}