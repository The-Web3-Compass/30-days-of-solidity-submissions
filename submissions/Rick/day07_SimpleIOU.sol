// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    // 银行管理员
    address private bankManager;
    //成员地址数组
    address[] memberList;
    // 成员是否添加权限
    mapping(address => bool) private registeredMembers;
    //每个成员存款余额 单位Wei
    mapping(address => uint) private balance;
    // 记录债权关系
    mapping(address=>mapping(address=>uint)) public debts;

    constructor() {
        bankManager = msg.sender;
        memberList.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }
    // 只有管理员可调用的函数
    modifier checkManager() {
        require(bankManager == msg.sender, unicode"不是管理员，不能操作");
        _;
    }

    //只有注册成员可调用的函数
    modifier checkRegester() {
        require(
            registeredMembers[msg.sender],
            unicode"不是已注册成员，不可以操作"
        );
        _;
    }

        // 成员注册
    function registe(address _account) public  checkManager{
        require(_account != address(0),unicode"不可为零地址");
        require(!registeredMembers[_account],unicode"该成员已注册，不可重复注册");
        require(_account != msg.sender,unicode"管理员在发布时已经自动注册，无需重复注册");

        memberList.push(_account);
        registeredMembers[_account] = true;
    }

    //记录债权关系，谁欠我N个ETH
    function recordDebt(address _account, uint _amount) public checkRegester {
        require(_account != address(0),unicode"地址不能为零地址");
        require(registeredMembers[_account],unicode"欠债人未注册");
        require(_amount>0,unicode"欠债金额必须大于0");

        debts[_account][msg.sender] = _amount;
    }

    //还钱
    // mapping 双层嵌套
    function payFromWallet(address _creditor,uint _amount) public {
        require(_creditor != address(0),unicode"地址不能为零地址");
        require(registeredMembers[_creditor],unicode"债权人未注册");
        require(_amount>0,unicode"还债金额必须大于0");
        require(debts[msg.sender][_creditor] >= _amount,unicode"还债金额大于欠债金额");
        require(balance[msg.sender] >= _amount,unicode"余额不足，无法还债");

        debts[msg.sender][_creditor] -= _amount;
        balance[msg.sender] -= _amount;
        balance[_creditor] += _amount;
    }

    /* 
        payable函数 
        意思是这个这个函数可以实质性接收ETH，哪怕没有内部代码，也能够接收成功
        该函数接收ETH是接收到合约代码对应的合约账户中
        发起方必须有足够的ETH
        如果没有payable修饰，会直接报错revert
        调用方式： depositIntoWallet{value: 1 ether}();
        场景一：王外部账户调用，一般是指充值场景  ETH从用户的钱包账户转到当前的合约账户
        场景二：合约账户A 调用合约账户B的payable函数 B(bAddr).receiveETH{value: msg.value}();

    */
    function depositIntoWallet() public payable checkRegester {
        require(msg.value > 0, "Must send ETH");
        balance[msg.sender] += msg.value;
    }

    /*
        只有payable修饰的请求参数address类型，_to才能调用transfer方法进行转账
        使用transfer 向目标地址转账
    */
    function transferEther(address payable  _to, uint _amount) public checkRegester{
        require(_to != address(0),unicode"地址不能为零地址");
        require(registeredMembers[_to],unicode"目标用户未注册");
        require(_amount>0,unicode"金额必须大于0");

        balance[msg.sender] -= _amount;
        _to.transfer(_amount);
        balance[_to] += _amount;
    }
    /*
        call方法，等同于上面的transfer，都是向目标账户转账
        区别：
        1.能返回转账是否成功的状态，手动判断返回值
        transfer 如果转账失败，会revert，并且消耗所有的gas
        2.transfer固定2300 gas限制
        call 不限制gas
    */
    function callEther01(address payable  _to, uint _amount) public checkRegester{
        require(_to != address(0),unicode"地址不能为零地址");
        require(registeredMembers[_to],unicode"目标用户未注册");
        require(_amount>0,unicode"欠债金额必须大于0");

        balance[msg.sender] -= _amount;
        (bool success ,) = _to.call{value : _amount}("");
        balance[_to] += _amount;
        require(success , unicode"call转账未成功");
    }

    // 与方法一 相同，都是通过call实现转账，只是payable声明的位置不同
    function callEther02( uint _amount) public checkRegester{
        require(_amount>0,unicode"欠债金额必须大于0");

        balance[msg.sender] -= _amount;
        (bool success ,) = payable(msg.sender).call{value : _amount}("");
        require(success , unicode"call转账未成功");
    }

    function checkBalance() public  view checkRegester returns (uint){
        return  balance[msg.sender];
    }
}
