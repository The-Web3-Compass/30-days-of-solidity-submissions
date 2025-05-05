// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FortKnoxVault
 * @author shivam
 * @notice A simple vault contract to demonstrate reentrancy vulnerabilities and prevention.
 * @dev Allows users to deposit and withdraw Ether. Contains both a vulnerable and a safe withdrawal function using a nonReentrant modifier.
 */
contract FortKnoxVault {
    // --- State Variables ---

    /// @notice Maps user addresses to their Ether balances within the vault.
    mapping(address => uint256) private balances;
    /// @dev Internal flag to prevent reentrancy in the safe withdrawal function.
    bool private _reentrancyLock;

    // --- Events ---

    /// @notice Emitted when a user successfully deposits Ether into the vault.
    /// @param user The address of the user who deposited.
    /// @param amount The amount of Ether deposited (in wei).
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user successfully withdraws Ether from the vault.
    /// @param user The address of the user who withdrew.
    /// @param amount The amount of Ether withdrawn (in wei).
    event Withdrew(address indexed user, uint256 amount);

    // --- Custom Errors ---

    /// @notice Error thrown when a user attempts to withdraw more Ether than their current balance.
    /// @param requested The amount the user tried to withdraw.
    /// @param available The user's actual available balance.
    error InsufficientBalance(uint256 requested, uint256 available);

    /// @notice Error thrown by the reentrancy guard modifier when a reentrant call is detected.
    error ReentrancyGuard();

    // --- Modifiers ---

    /**
     * @notice Prevents reentrant calls to a function.
     * @dev Uses a boolean flag `_reentrancyLock` to guard against recursive calls.
     * @custom:error ReentrancyGuard If a reentrant call is detected (`_reentrancyLock` is true).
     */
    modifier nonReentrant() {
        if (_reentrancyLock) revert ReentrancyGuard();
        // Set lock before function execution
        _reentrancyLock = true;
        // execute the function
        _;
        // Reset lock after function execution
        _reentrancyLock = false;
    }

    // --- Functions ---

    /**
     * @notice Allows users to deposit Ether into the vault.
     * @dev Increases the sender's balance by the amount of Ether sent with the transaction.
     */
    function deposit() external payable {
        uint256 amount = msg.value;
        // No need to check amount > 0, as sending 0 value is valid but does nothing here.
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Allows users to withdraw a specified amount of Ether. THIS FUNCTION IS VULNERABLE.
     * @dev Checks balance, sends Ether, then updates the balance (Incorrect order: Checks-Interactions-Effects).
     * @param _amount The amount of Ether (in wei) the user wishes to withdraw.
     * @custom:error InsufficientBalance If the requested amount exceeds the user's balance.
     */
    function withdrawVulnerable(uint256 _amount) external {
        uint256 userBalance = balances[msg.sender];
        if (_amount > userBalance) revert InsufficientBalance(_amount, userBalance);

        // vulnerable part
        // Send Ether *before* updating the balance. If msg.sender is a contract,
        // its fallback/receive function can call back into this function.
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed"); // Check if the transfer was successful

        // update state (too late)
        // Balance is updated *after* the external call, allowing reentrancy
        balances[msg.sender] = userBalance - _amount;

        emit Withdrew(msg.sender, _amount);
    }

    /**
     * @notice Allows users to withdraw a specified amount of Ether safely.
     * @dev Uses the `nonReentrant` modifier and follows the Checks-Effects-Interactions pattern.
     * @param _amount The amount of Ether (in wei) the user wishes to withdraw.
     * @custom:error InsufficientBalance If the requested amount exceeds the user's balance.
     */
    function withdrawSafe(uint256 _amount) external nonReentrant {
        uint256 userBalance = balances[msg.sender];
        if (_amount > userBalance) revert InsufficientBalance(_amount, userBalance);

        // update state (before interaction)
        // Update the balance *before* the external call.
        balances[msg.sender] = userBalance - _amount;

        // interaction
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdrew(msg.sender, _amount);
    }

    /**
     * @notice Returns the current Ether balance of the calling address within the vault.
     * @return balance The Ether balance (in wei).
     */
    function getBalance() external view returns (uint256 balance) {
        balance = balances[msg.sender];
    }

    /**
     * @notice Returns the total Ether balance held by this contract.
     * @dev Useful for verifying the contract's state during testing/demonstration.
     * @return totalBalance The total Ether balance (in wei).
     */
     function getTotalVaultBalance() external view returns (uint256 totalBalance) {
         totalBalance = address(this).balance;
     }
}