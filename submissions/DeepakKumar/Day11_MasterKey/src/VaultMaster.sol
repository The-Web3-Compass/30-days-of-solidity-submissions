// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

///VaultMaster - Secure vault controlled by the Master Key holder
/// Only the owner can deposit or withdraw ETH
contract VaultMaster is Ownable {
    uint256 public totalDeposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    /// Allows the owner to deposit ETH
    function deposit() external payable onlyOwner {
        require(msg.value > 0, "No ETH sent");
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// Allows the owner to withdraw ETH

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        totalDeposits -= amount;
        emit Withdraw(to, amount);
        to.transfer(amount);
    }

    /// View contract balance
    function getVaultBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
