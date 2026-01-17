// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleIOU {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) private debts;

    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        balances[msg.sender] += msg.value;
    }

    function recordDebt(address creditor, uint256 amount) external {
        require(creditor != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        debts[msg.sender][creditor] += amount;
    }

    function repayFromBalance(address creditor, uint256 amount) external {
        require(creditor != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][creditor] >= amount, "Debt too small");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[creditor] += amount;
        debts[msg.sender][creditor] -= amount;
    }

    function transferBalance(address to, uint256 amount) external {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;
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

    function getDebt(address debtor, address creditor) external view returns (uint256) {
        return debts[debtor][creditor];
    }
}