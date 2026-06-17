// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    mapping(address => uint) public balances;

    // Deposit Ether into your piggy bank
    function deposit() public payable {
        require(msg.value > 0, "Send some Ether");
        balances[msg.sender] += msg.value;
    }

    // Withdraw your saved Ether
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Check your balance (optional since it's public)
    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}
