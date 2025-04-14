// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title VaultMaster
 * @dev A secure vault contract that only the owner can control
 */
contract VaultMaster is Ownable {
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    // Minimum time required between withdrawals (in seconds)
    uint256 public constant WITHDRAWAL_COOLDOWN = 1 days;
    
    // Timestamp of the last withdrawal
    uint256 private _lastWithdrawalTime;
    
    // Emergency withdrawal flag
    bool private _emergencyMode;

    /**
     * @dev Constructor inherits Ownable constructor
     */
    constructor() Ownable() {}

    /**
     * @dev Allows anyone to deposit ETH into the vault
     */
    function deposit() public payable {
        require(msg.value > 0, "VaultMaster: deposit amount must be greater than 0");
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows the owner to withdraw funds with a cooldown period
     * @param amount The amount to withdraw in wei
     */
    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "VaultMaster: withdrawal amount must be greater than 0");
        require(amount <= address(this).balance, "VaultMaster: insufficient balance");
        require(block.timestamp >= _lastWithdrawalTime + WITHDRAWAL_COOLDOWN, "VaultMaster: withdrawal cooldown not met");
        
        _lastWithdrawalTime = block.timestamp;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "VaultMaster: withdrawal failed");
        
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Allows the owner to enable emergency mode
     */
    function enableEmergencyMode() public onlyOwner {
        _emergencyMode = true;
    }

    /**
     * @dev Allows the owner to withdraw all funds in emergency mode
     */
    function emergencyWithdraw() public onlyOwner {
        require(_emergencyMode, "VaultMaster: emergency mode not enabled");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "VaultMaster: no funds to withdraw");
        
        _emergencyMode = false; // Disable emergency mode after withdrawal
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "VaultMaster: emergency withdrawal failed");
        
        emit EmergencyWithdrawal(msg.sender, balance);
    }

    /**
     * @dev Returns the current balance of the vault
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the timestamp of the last withdrawal
     */
    function getLastWithdrawalTime() public view returns (uint256) {
        return _lastWithdrawalTime;
    }

    /**
     * @dev Returns whether emergency mode is enabled
     */
    function isEmergencyMode() public view returns (bool) {
        return _emergencyMode;
    }

    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {
        deposit();
    }
} 