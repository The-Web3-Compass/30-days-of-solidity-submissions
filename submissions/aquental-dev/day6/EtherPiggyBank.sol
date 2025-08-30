// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A simple digital piggy bank contract to manage Ether deposits and withdrawals.
contract EtherPiggyBank {
    // Mapping to store the balance of each user, identified by their address.
    mapping(address => uint256) private balances;

    // Event emitted when a user deposits Ether.
    event Deposited(address indexed user, uint256 amount);

    // Event emitted when a user withdraws Ether.
    event Withdrawn(address indexed user, uint256 amount);

    // Deposits Ether into the user's piggy bank.
    // The amount is sent via msg.value and credited to msg.sender's balance.
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Withdraws a specified amount of Ether from the user's piggy bank.
    // Ensures the user has sufficient balance before transferring.
    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Update balance before transfer to prevent reentrancy attacks.
        balances[msg.sender] -= amount;

        // Transfer Ether to the user. Using call for safer Ether transfer.
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // Retrieves the balance of the calling user.
    // View function to allow gas-free queries.
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
