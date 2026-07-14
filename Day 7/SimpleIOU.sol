// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleIOU {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function recordDebt(address to, uint256 amount) external {
        require(to != msg.sender, "Cannot owe yourself");
        require(amount > 0, "Invalid amount");
        debts[msg.sender][to] += amount;
    }

    function repayDebt(address to, uint256 amount) external {
        require(debts[msg.sender][to] >= amount, "Debt too small");
        require(balances[msg.sender] >= amount, "Not enough balance");
        debts[msg.sender][to] -= amount;
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function settleDebt(address to) external payable {
        require(to != msg.sender, "Cannot settle with yourself");
        uint256 debt = debts[msg.sender][to];
        require(debt > 0, "No debt to settle");
        require(msg.value > 0, "Must send ETH");
        require(msg.value <= debt, "Cannot overpay");
        debts[msg.sender][to] -= msg.value;
        payable(to).transfer(msg.value);
    }

    function checkDebt(address from, address to) external view returns (uint256) {
        return debts[from][to];
    }
}
