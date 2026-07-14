// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EtherPiggyBank {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        uint256 bal = balances[msg.sender];
        require(amount > 0, "Amount must be greater than 0");
        require(bal >= amount, "Insufficient balance");

        balances[msg.sender] = bal - amount;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Transfer failed");
    }

    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}