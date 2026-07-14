// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title GoldVault
/// @notice 一个模拟存取金库的合约，包含不安全与安全两种提现方式，演示重入攻击防范
contract GoldVault {
    mapping(address => uint256) public goldBalance;

    // 状态变量用于非重入锁（reentrancy guard）
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /// @notice 自定义的防重入修饰符
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /// @notice 向金库存入 ETH
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be more than 0");
        goldBalance[msg.sender] += msg.value;
    }

    /// @dev 不安全的提现函数，存在重入攻击风险（先转账后修改状态）
    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // ⚠️ 先转账，后更新余额 —— 重入攻击的根源
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        goldBalance[msg.sender] = 0;
    }

    /// @notice 安全的提现函数，使用 nonReentrant 防止攻击
    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // ✅ 先修改状态，再调用外部地址
        goldBalance[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}
