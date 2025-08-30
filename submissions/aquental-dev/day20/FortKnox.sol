// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title FortKnox
/// @notice A secure digital vault for depositing and withdrawing tokenized gold (or any ERC20 asset), protected against reentrancy attacks.
/// @dev Implements a nonReentrant modifier to prevent reentrancy and follows Solidity security best practices.
contract FortKnox is ReentrancyGuard {
    /// @notice The ERC20 token representing tokenized gold.
    /// @dev Immutable to prevent unauthorized changes after deployment.
    IERC20 public immutable goldToken;

    /// @notice Tracks the balance of tokenized gold for each user.
    /// @dev Maps user addresses to their deposited token balance.
    mapping(address => uint256) public balances;

    /// @notice Emitted when a user deposits tokenized gold into the vault.
    /// @param user The address of the user making the deposit.
    /// @param amount The amount of tokens deposited.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws tokenized gold from the vault.
    /// @param user The address of the user withdrawing tokens.
    /// @param amount The amount of tokens withdrawn.
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Initializes the contract with the tokenized gold contract address.
    /// @dev Sets the immutable goldToken address and ensures it's valid.
    /// @param _goldToken The address of the ERC20 token contract (e.g., tokenized gold).
    constructor(address _goldToken) {
        require(_goldToken != address(0), "Invalid token address");
        goldToken = IERC20(_goldToken);
    }

    /// @notice Allows a user to deposit tokenized gold into the vault.
    /// @dev Transfers tokens from the user to the contract and updates their balance.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");

        // Update balance before transfer to follow Checks-Effects-Interactions pattern
        balances[msg.sender] += amount;

        // Transfer tokens to the contract; reverts on failure
        bool success = goldToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "Token transfer failed");

        emit Deposited(msg.sender, amount);
    }

    /// @notice Allows a user to withdraw their tokenized gold from the vault.
    /// @dev Uses nonReentrant modifier to prevent reentrancy attacks and follows Checks-Effects-Interactions.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Update balance first to prevent reentrancy
        balances[msg.sender] -= amount;

        // Transfer tokens to the user; reverts on failure
        bool success = goldToken.transfer(msg.sender, amount);
        require(success, "Token transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Returns the contract's balance of tokenized gold.
    /// @dev Useful for auditing and verifying the vault's total holdings.
    /// @return The total balance of tokens held by the contract.
    function vaultBalance() external view returns (uint256) {
        return goldToken.balanceOf(address(this));
    }
}
