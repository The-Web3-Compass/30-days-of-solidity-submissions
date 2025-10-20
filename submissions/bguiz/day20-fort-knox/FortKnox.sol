// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FortKnox
 * @dev Build a secure digital vault where users can deposit and withdraw tokenized gold (or any valuable asset),
 * ensuring it's protected from reentrancy attacks.
 * Imagine you're creating a decentralized version of Fort Knox — users lock up tokenized gold, and can later withdraw it.
 * But just like a real vault, this contract must prevent attackers from repeatedly triggering the withdrawal logic
 * before the balance updates.
 * You'll implement the `nonReentrant` modifier to block reentry attempts,
 * and follow Solidity security best practices to lock down your contract.
 * This project shows how a seemingly simple withdrawal function can become a vulnerability —
 * and how to defend it properly.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 19
 */
abstract contract FortKnox is Ownable {
    enum ENTRANCY_STATUS {
        NOT_ENTERED,
        ENTERED
    }

    ENTRANCY_STATUS public entrancyStatus;
    mapping(address => uint256) balances;


    constructor() Ownable(msg.sender) {
        entrancyStatus = ENTRANCY_STATUS.NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(entrancyStatus == ENTRANCY_STATUS.NOT_ENTERED, "reentrancy attempt blocked");
        entrancyStatus = ENTRANCY_STATUS.ENTERED;
        _;
        entrancyStatus = ENTRANCY_STATUS.NOT_ENTERED;
    }

    function deposit() public payable {
        require(msg.value > 0, "deposit amount must be more than zero");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public nonReentrant {
        require(amount > 0 && amount <= balances[msg.sender], "withdraw amount not allowed");
        balances[msg.sender] -= amount;
        (bool transferSuccess,) = payable(msg.sender).call{ value: amount }("");
        require(transferSuccess, "transfer failed");
    }
}
