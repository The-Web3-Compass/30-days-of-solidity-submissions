// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract EtherPiggyBank {
    mapping(address => uint) public balances;

    function deposit() public payable {
        require(msg.value > 0, "No ETH sent");

        balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}