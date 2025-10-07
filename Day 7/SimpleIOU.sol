// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    mapping(address => uint) public balances; 
    mapping(address => mapping(address => uint)) public debts; 

    // Deposit ETH to your balance
    function deposit() public payable {
        require(msg.value > 0, "Send some ETH");
        balances[msg.sender] += msg.value;
    }

    // Record a debt: sender owes 'to' an amount
    function borrow(address to, uint amount) public {
        require(balances[to] >= amount, "Lender has insufficient funds");
        debts[msg.sender][to] += amount;
    }

    // Repay a debt
    function repay(address to) public payable {
        require(msg.value > 0, "Send ETH to repay");
        require(debts[msg.sender][to] >= msg.value, "Repaying more than owed");

        debts[msg.sender][to] -= msg.value;
        payable(to).transfer(msg.value);
    }

    // Check how much you owe someone
    function checkDebt(address to) public view returns (uint) {
        return debts[msg.sender][to];
    }
}
