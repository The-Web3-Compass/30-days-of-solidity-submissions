// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank {
    mapping(address => uint256) balances;

    function deposit() public payable {
        uint256 amount = msg.value;
        require(amount > 0, "Enter a value above 0");

        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external{
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transaction failed");
        
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

}