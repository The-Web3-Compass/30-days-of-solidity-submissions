// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

/// @title VaultMaster - Secure vault controlled by the owner (MasterKey)
contract VaultMaster is Ownable {
    event Deposit(address indexed from, uint amount);
    event Withdrawal(address indexed to, uint amount);

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Allows the owner to withdraw ETH from the contract
    /// @param amount The amount of ETH to withdraw
    function withdraw(uint amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
        emit Withdrawal(owner, amount);
    }

    /// @notice Returns the current balance of the vault
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}
