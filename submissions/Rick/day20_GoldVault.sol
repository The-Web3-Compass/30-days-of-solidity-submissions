 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GoldVault {
    // 金库存额 用户存了多少钱
    mapping(address => uint256) public goldBalance;

    // 锁 状态
    uint256 private _status;
    // 开启状态
    uint256 private constant _NOT_ENTERED = 1;
    // 关闭状态
    uint256 private constant _ENTERED = 2;

    // 初始化开启
    constructor() {
        _status = _NOT_ENTERED;
    }

    /*
        不可重入锁
        
        重入攻击的发生，主要是第一次请求赎回时，在黑客合约中receive 递归调用，还是处于同一个交易，是共享上下文的，所以第二次调用赎回接口时，_status=_ENTERED，接口被锁住了，不能进行第二次赎回

        重入攻击发生在同一笔交易内；
        是因为调用栈共享、状态尚未更新；
        nonReentrant 的防护逻辑正是基于同一交易上下文的锁机制；
        不同交易（即便是同一个黑客发起的）各自独立，不会被 _status 影响。
    */
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // 存入金库
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be more than 0");
        goldBalance[msg.sender] += msg.value;
    }

    // 提取金金币，有风险
    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        goldBalance[msg.sender] = 0;
    }

    // 提取金金币，安全
    // 调整代码顺序
    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        goldBalance[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}

