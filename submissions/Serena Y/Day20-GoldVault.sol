// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GoldVault{
    mapping(address=>uint256) public goldBalance;//映射 地址对应金库金额

    uint256 private _status;//是当前状态变量。
    uint256 private constant _NOT_ENTERED=1;//表示函数没有在执行
    uint256 private constant _ENTERED=2;//当前函数已经进入执行状态

    event Deposit(address indexed who, uint256 amount);

    constructor(){//表示函数没有在执行
        _status=_NOT_ENTERED;
    }

    modifier nonReentrant(){
        require(_status!=_ENTERED,"Reentrant call blocked");//检查当前函数是否已经在执行
        _status=_ENTERED;//标记“我正在执行函数”。
        _;//此处执行原始函数的内容”
        _status=_NOT_ENTERED;//函数执行完毕后，把状态解锁，允许下次正常调用
    }
    //存钱
    function deposit() external payable{
        uint256 amount= msg.value;
        require(amount>0,"Deposit must be more than 0");
        goldBalance[msg.sender]+=msg.value;
        emit Deposit(msg.sender,amount);
    }
     // 这个函数没有防止重入的保护措施
    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];//用户余额等于amount
        require(amount > 0, "Nothing to withdraw");//用户余额需要大于0

        (bool sent, ) = msg.sender.call{value: amount}("");//提现amount金额给msg.sender
        require(sent, "ETH transfer failed");

        goldBalance[msg.sender] = 0;//提现完成余额为0
    }
    // 这个函数有防止重入的保护措施
    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        goldBalance[msg.sender] = 0;//先更新账本再进行转账
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }


    }





