// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EtherPiggyBank {

    // Mapping to track each user's deposited balance
    mapping(address => uint) public balances;

    // Deposit Ether into the piggy bank
    function deposit() public payable {
        require(msg.value > 0, "Must send some Ether");
        balances[msg.sender] += msg.value;
    }

    // Withdraw Ether from the piggy bank
    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Withdrawal failed");
    }

    // Check contract's total Ether balance
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
}