//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GoldVault {
    mapping(address => uint256) public balance;
    uint256 private constant ENTERED = 1;
    uint256 private constant NOT_ENTERED = 2;
    uint256 private status;

    constructor() {
        status = NOT_ENTERED;
    }

    // 防止重入攻击
    modifier nonReentrant() {
        require(status != ENTERED, "No reentrant");
        status = ENTERED;
        _;
        status = NOT_ENTERED;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount should be greater than 0");

        balance[msg.sender] += msg.value;
    }

    // 有漏洞的，会被重入攻击的取款
    function vulnerableWithdraw() external {
        uint256 amount = balance[msg.sender];
        require(amount > 0, "Insufficient balance");

        (bool success, ) = msg.sender.call{value : amount}("");
        require(success, "Withdraw failed");

        balance[msg.sender] = 0;
    }

    // 安全的取款：1.nonReentrant modifier的保护，2.先把balance置零
    function safeWithdraw() external nonReentrant {
        uint256 amount = balance[msg.sender];
        require(amount > 0, "Insufficient balance");

        balance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");
    }
}