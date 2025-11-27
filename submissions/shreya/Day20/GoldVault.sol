// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 A secure vault for depositing and withdrawing ETH, protected from
 reentrancy attacks using a nonReentrant modifier.
 */
contract GoldVault {
    mapping(address => uint256) public balances;
    bool private locked; // Our reentrancy guard lock

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor() {
        locked = false; // The lock is initially open
    }

    /**
     A modifier to prevent reentrancy attacks.
     */
    modifier nonReentrant() {
        require(!locked, "Reentrancy attempt detected!");
        locked = true;  // Lock the function
        _;              // Execute the original function code
        locked = false; // Unlock the function after execution
    }

    receive() external payable {}

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     Withdraws the sender's entire balance securely.
        This function now uses the nonReentrant modifier and follows the
     Checks-Effects-Interactions pattern.
     */
    function withdraw() external nonReentrant {
        // 1. CHECKS: Check the user's balance first.
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Insufficient balance");

        // 2. EFFECTS: Update the state *before* the interaction.
        // This is the most crucial part of the fix.
        balances[msg.sender] = 0;

        // 3. INTERACTION: Send the ETH.
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        emit Withdrawn(msg.sender, balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}