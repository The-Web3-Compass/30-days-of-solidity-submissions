//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GoldVault {

    //映射，每个地址（用户）对应一个 ETH 余额
    mapping(address => uint256) public goldBalance;

    //重入锁机制（Reentrancy Lock）
    uint256 private _status;     //当前锁的状态
    uint256 private constant _NOT_ENTERED = 1;     //当前没有函数在执行，门是“开”的
    uint256 private constant _ENTERED = 2;     //当前函数执行中，门“锁上了”
    //当一个敏感函数（如提币）正在运行时，不允许再次进入
    
    //构造函数（部署初始化）
    //部署合约时执行一次，初始化锁的状态为“未进入”
    //也就是让系统一开始处于“门是开的”状态，准备接受调用
    constructor() {
        _status = _NOT_ENTERED;
    }

    //nonReentrant 修饰器（核心防御）
    modifier nonReentrant() {

        //检查当前是否还有人以已经在执行这个函数
        require(_status != _ENTERED, "Reentrant call blocked");   

        //如果...，说明函数还没执行完，就被再次调用 → 阻止执行，防御重入攻击
        _status = _ENTERED;
        _;

        //函数执行完毕后，把锁打开，让下一个调用可以继续
        _status = _NOT_ENTERED;
    }
    //这个修饰器相当于在函数门口挂了一个“正在使用，请稍后”的牌子，保证一个函数调用过程中不会被重入

    //存款函数 deposit()
    //external payable：表示该函数可以被外部账户调用，并且能接收 ETH
    function deposit() external payable {

        //检查转入的金额是否大于 0
        require(msg.value > 0, "Deposit must be more than 0");

        //将用户发送的 ETH 数量累计到他们的账户余额中
        goldBalance[msg.sender] += msg.value;
    }
    //用户往金库里存钱（ETH），系统记录下他们的余额

    //不安全的提取函数 vulnerableWithdraw()
    function vulnerableWithdraw() external {

        //读取用户余额
        uint256 amount = goldBalance[msg.sender];

        //检查是否有可提取金额
        require(amount > 0, "Nothing to withdraw");
        
        //向用户发送 ETH
        //这里用 call 而不是 transfer，是允许外部合约执行回调的危险点！
        (bool sent, ) = msg.sender.call{value: amount}("");

        //检查发送是否成功
        require(sent, "ETH transfer failed");
        
        //更新余额为 0
        goldBalance[msg.sender] = 0;
    }

    //安全的提取函数 safeWithdraw()
    //external nonReentrant：允许外部调用，并开启防重入保护锁
    function safeWithdraw() external nonReentrant {

        //获取用户余额
        uint256 amount = goldBalance[msg.sender];

        //检查余额必须大于 0
        require(amount > 0, "Nothing to withdraw");

        //先清零余额（重要！），防止重入调用时余额仍为正
        goldBalance[msg.sender] = 0;

        //把 ETH 发回用户
        (bool sent, ) = msg.sender.call{value: amount}("");

        //检查发送是否成功
        require(sent, "ETH transfer failed");
    }
}
