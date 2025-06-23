// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "./Ownable.sol";

contract VaultMaster is Ownable {
    error VaultMaster_Paused();
    error VaultMaster_NotPaused();
    error VaultMaster_InvalidAmount();

    bool public paused = false;

    event DepositSuccessful(address indexed depositor, uint256 amount);
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    constructor() Ownable() {}

    modifier whenNotPaused {
        if (paused) revert VaultMaster_Paused();
        _;
    }

    modifier whenPaused {
        if (!paused) revert VaultMaster_NotPaused();
        _;
    }

    /**
     * @dev Deposit ETH into the vault. Anyone can deposit when not paused.
     */
    function deposit() external payable whenNotPaused {
        if (msg.value == 0) revert VaultMaster_InvalidAmount();
        emit DepositSuccessful(msg.sender, msg.value);
    }

    /**
     * @dev Pause the contract. Only owner can pause.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpause the contract. Only owner can unpause.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Emergency withdraw - bypasses pause state.
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Ownable_InsufficientBalance();
        
        (bool success,) = payable(getOwner()).call{value: balance}("");
        if (!success) revert Ownable_TransferFailed();
        
        emit WithdrawSuccessful(getOwner(), balance);
    }

    /**
     * @dev Override withdraw to respect pause state.
     */
    function withdraw(uint256 _amount) public override onlyOwner whenNotPaused {
        super.withdraw(_amount);
    }

    /**
     * @dev Allow contract to receive ETH directly.
     */
    receive() external payable whenNotPaused {
        emit DepositSuccessful(msg.sender, msg.value);
    }

    /**
     * @dev Fallback function for direct ETH sends.
     */
    fallback() external payable whenNotPaused {
        emit DepositSuccessful(msg.sender, msg.value);
    }
}