// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title AdminOnly
 * @dev Build a contract that simulates a treasure chest controlled by an owner.
 * The owner can add treasure, approve withdrawals for specific users, and even withdraw treasure themselves.
 * Other users can attempt to withdraw, but only if the owner has given them an allowance and they haven't withdrawn before.
 * The owner can also reset withdrawal statuses and transfer ownership of the treasure chest.
 * This demonstrates how to create a contract with restricted access using a 'modifier' and `msg.sender`,
 * similar to how only an admin can perform certain actions in a game or application.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 5
 */
contract AdminOnly {
    address public owner;
    mapping(address => uint256) public treasure;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only onwer is allowed to perform this action");
        _;
    }

    function addTreasure(address recipient, uint256 amount) public onlyOwner {
        require(recipient != owner, "not allowed to add treasure for self");
        treasure[recipient] += amount;
    }

    function withdrawTreasure(uint256 amount) public {
        require(msg.sender != owner, "not allowed to withdraw treasure to owner");
        require(treasure[msg.sender] >= amount, "unable to withdraw more treasure than allowance");
        treasure[msg.sender] -= amount;
    }
}
