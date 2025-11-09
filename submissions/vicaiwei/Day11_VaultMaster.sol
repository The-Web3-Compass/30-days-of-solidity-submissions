// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

contract VaultMaster is Ownable {
    // logs the external account or contract that funded the vault
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawlSuccessful(address indexed recipient, uint256 value);

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Accept ETH via explicit deposit
    function deposit() public payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    // Owner-only withdrawal
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawlSuccessful(to, amount);
    }

    // Accept ETH via receive 
    receive() external payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }
}