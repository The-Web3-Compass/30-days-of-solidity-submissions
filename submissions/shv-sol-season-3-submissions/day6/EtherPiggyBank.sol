// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title EtherPiggyBank
 * @dev A simple digital piggy bank where users can deposit and withdraw Ether.
 * Each user's balance is tracked using their address via a mapping.
 * Demonstrates basic use of `msg.sender`, `address`, and Ether transfers.
 */


contract EtherPiggyBank {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        require(msg.value > 0, "Must send some Ether");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
