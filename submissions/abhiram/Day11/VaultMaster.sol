// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./Ownable.sol";

/**
 * @title VaultMaster
 * @dev A secure vault contract that only the owner (master key holder) can control
 * @notice This contract inherits from Ownable to implement access control for fund management
 */
contract VaultMaster is Ownable {
    // Track total deposits made to the vault
    uint256 private totalDeposits;
    
    // Mapping to track individual user balances
    mapping(address => uint256) private balances;

    // Events for tracking vault activities
    event Deposit(address indexed depositor, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed owner, uint256 amount, address indexed recipient, uint256 timestamp);
    event EmergencyWithdrawal(address indexed owner, uint256 amount, uint256 timestamp);

    /**
     * @dev Constructor sets the deployer as the vault owner
     */
    constructor() Ownable() {
        // Owner is set in Ownable constructor
    }

    /**
     * @dev Allows anyone to deposit ETH into the vault
     * @notice Funds deposited are tracked per user for transparency
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Allows the owner to withdraw a specific amount from the vault
     * @param amount The amount of ETH to withdraw (in wei)
     * @param recipient The address to send the withdrawn funds to
     * @notice Only the owner (master key holder) can call this function
     */
    function withdraw(uint256 amount, address payable recipient) external onlyOwner {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(recipient != address(0), "Cannot withdraw to zero address");
        require(address(this).balance >= amount, "Insufficient balance in vault");
        
        // Transfer the funds
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount, recipient, block.timestamp);
    }

    /**
     * @dev Allows the owner to withdraw all funds from the vault
     * @param recipient The address to send all withdrawn funds to
     * @notice Emergency function - only owner can call
     */
    function withdrawAll(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw to zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "Vault is empty");

        // Transfer all funds
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Transfer failed");

        emit EmergencyWithdrawal(msg.sender, balance, block.timestamp);
    }

    /**
     * @dev Returns the current balance of the vault
     * @return The total ETH balance held in the vault (in wei)
     */
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the total amount deposited by a specific address
     * @param depositor The address to check
     * @return The total amount deposited by the address (in wei)
     */
    function getDepositorBalance(address depositor) external view returns (uint256) {
        return balances[depositor];
    }

    /**
     * @dev Returns the total deposits ever made to the vault
     * @return The cumulative sum of all deposits (in wei)
     */
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    /**
     * @dev Fallback function to accept ETH sent directly to the contract
     * @notice Automatically deposits any ETH sent to the contract
     */
    receive() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Fallback function for when no other function matches
     */
    fallback() external payable {
        revert("Function does not exist");
    }
}
