/*---------------------------------------------------------------------------
  File:   SimpleIOU.sol
  Author: Marion Bohr
  Date:   04/07/2025
  Description:
    Build a simple IOU contract for a private group of friends. Each user 
    can deposit ETH, track personal balances, log who owes who, and settle 
    debts — all on-chain. You’ll learn how to accept real Ether using 
    `payable`, transfer funds between addresses, and use nested mappings to 
    represent relationships like 'Alice owes Bob'. This contract mirrors 
    real-world borrowing and lending, and teaches you how to model those 
    interactions in Solidity.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleIOU {
    // Each user has their balance
    mapping(address => uint256) public balances;

    // Depts: Who owes how much to whom?
    mapping(address => mapping(address => uint256)) public debts;

    // Deposit ETH
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH to deposit.");
        balances[msg.sender] += msg.value;
    }

    // Show balance
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    // Record a debt: msg.sender owes 'to' an amount
    function iOwe(address to, uint256 amount) external {
        require(msg.sender != to, "You cannot owe yourself.");
        require(amount > 0, "Amount must be greater than 0.");
        debts[msg.sender][to] += amount;
    }

    // View a friend's debts
    function getDebt(address from, address to) external view returns (uint256) {
        return debts[from][to];
    }

    // Pay off debts
    function settleDebt(address to) external {
        uint256 amountOwed = debts[msg.sender][to];
        require(amountOwed > 0, "No debt to settle.");
        require(balances[msg.sender] >= amountOwed, "Not enough balance.");

        balances[msg.sender] -= amountOwed;
        balances[to] += amountOwed;
        debts[msg.sender][to] = 0;
    }

    // Pay out ETH to an address
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    // Direct transfer to a friend
    function sendToFriend(address payable friend, uint256 amount) external {
        require(friend != msg.sender, "Can't send to yourself.");
        require(balances[msg.sender] >= amount, "Insufficient funds.");
        balances[msg.sender] -= amount;

        (bool success, ) = friend.call{value: amount}("");
        require(success, "Transfer failed.");
    }
}
