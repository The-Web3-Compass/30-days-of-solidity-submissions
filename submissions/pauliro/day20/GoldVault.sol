// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
    Build a secure digital vault where users can deposit and withdraw tokenized gold 
    (or any valuable asset), ensuring it's protected from reentrancy attacks. 
    Imagine you're creating a decentralized version of Fort Knox — users lock up tokenized gold, 
    and can later withdraw it. 
    But just like a real vault, this contract must prevent attackers from repeatedly 
    triggering the withdrawal logic before the balance updates. 
    You'll implement the `nonReentrant` modifier to block reentry attempts, 
    and follow Solidity security best practices to lock down your contract. 
    This project shows how a seemingly simple withdrawal function can become 
    a vulnerability — and how to defend it properly.
*/    

contract GoldVault {
    mapping(address => uint256) public goldBalance;

    // Reentrancy lock setup
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    // Custom nonReentrant modifier — locks the function during execution
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be more than 0");
        goldBalance[msg.sender] += msg.value;
    }

    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        goldBalance[msg.sender] = 0;
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        goldBalance[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}

