/*---------------------------------------------------------------------------
  File:   EtherPiggyBank.sol
  Author: Marion Bohr
  Date:   04/06/2025
  Description:
    Let's make a digital piggy bank! Users can deposit and withdraw Ether 
    (the cryptocurrency). You'll learn how to manage balances (using 
    `address` to identify users) and track who sent Ether (using 
    `msg.sender`). It's like a simple bank account on the blockchain, 
    demonstrating how to handle Ether and user addresses.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract EtherPiggyBank {
    // Mapping to track Ether balances by address
    mapping(address => uint256) public balances;

    // Deposit function: Allows users to send Ether to the contract
    function deposit() external payable {
        require(msg.value > 0, "Send some Ether to deposit.");
        balances[msg.sender] += msg.value;
    }

    // Withdraw function: Allows users to withdraw their Ether
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // View balance of the sender
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
}