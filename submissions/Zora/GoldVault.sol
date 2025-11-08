// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GoldVault {
    mapping(address => uint256) public goldBalance; //纪录每个用户存了多少黄金
    
    //重入锁系统
    uint256 private _status; //纪录敏感函数的调用状态
    uint256 private constant _NOT_ENTERED = 1; //未被使用，可以使用
    uint256 private constant _ENTERED = 2; //已经使用，阻止使用

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked");
        _status = _ENTERED; //上锁
        _;
        _status = _NOT_ENTERED; //解锁
    }
    
    //允许用户存ETH
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be more than 0");
        goldBalance[msg.sender] += msg.value;
    }
    
    //存在重入漏洞，在更新用户余额之前发送ETH
    //用户调用这个函数，可以重复调用，导致多次提取ETH
    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        goldBalance[msg.sender] = 0;
    }
    
    //使用nonReetrant修饰符来防护
    //checks-effects-interactions
    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        goldBalance[msg.sender] = 0; 
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}


