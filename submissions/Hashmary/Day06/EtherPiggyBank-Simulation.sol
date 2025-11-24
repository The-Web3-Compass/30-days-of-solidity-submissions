/*---------------------------------------------------------------------------
  File:   EtherPiggyBank-Simulation.sol
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

contract etherPiggyBank {
    // Simulated "deposits" per user
    mapping(address => uint256) public balances;

    // Simulated "deposit"
    function simulateDeposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        balances[msg.sender] += amount;
    }

    // Simulated "withdrawl"
    function simulateWithdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough funds.");
        balances[msg.sender] -= amount;
        // Hier würde normalerweise transfer() stehen, aber wir simulieren nur
    }

    // Show balance
    function getMySimulatedBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
}
