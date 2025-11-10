// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

// VaultMaster - A secure vault controlled exclusively by the owner
// Users can deposit ETH, but only the owner can withdraw
contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    // Allows anyone to deposit ETH into the vault
    function deposit() external payable {
        require(msg.value > 0, "Vault: deposit amount must be > 0");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    // Returns the current ETH balance held by the contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Allows only the owner to withdraw ETH from the vault
    // to Recipient address for the withdrawn funds
    // amount Amount of ETH to withdraw (in wei)
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Vault: invalid recipient");
        require(amount <= address(this).balance, "Vault: insufficient balance");

        (bool success, ) = to.call{value: amount}("");
        require(success, "Vault: transfer failed");

        emit WithdrawSuccessful(to, amount);
    }

    // Fallback function to accept plain ETH transfers
    receive() external payable {
        emit DepositSuccessful(msg.sender, msg.value);
    }

    fallback() external payable {
        emit DepositSuccessful(msg.sender, msg.value);
    }
}
