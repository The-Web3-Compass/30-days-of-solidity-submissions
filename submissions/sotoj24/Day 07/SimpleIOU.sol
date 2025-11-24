// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {

    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public debts;

    function deposit() external payable {
        require(msg.value > 0, "Must deposit some Ether");
        balances[msg.sender] += msg.value;
    }

    function borrow(address lender, uint256 amount) external {
        require(lender != msg.sender, "Cannot owe yourself");
        require(amount > 0, "Amount must be positive");
        debts[msg.sender][lender] += amount;
    }

    function repayDebt(address lender) external {
        uint256 amountOwed = debts[msg.sender][lender];
        require(amountOwed > 0, "No debt to repay");
        require(balances[msg.sender] >= amountOwed, "Insufficient balance");

        balances[msg.sender] -= amountOwed;
        debts[msg.sender][lender] = 0;
        balances[lender] += amountOwed;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getDebt(address borrower, address lender) external view returns (uint256) {
        return debts[borrower][lender];
    }
}
