// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    // Track each user's ETH balance
    mapping(address => uint256) public balances;

    // Nested mapping: debts[borrower][lender] = amount owed
    mapping(address => mapping(address => uint256)) public debts;

    // Events for transparency
    event Deposited(address indexed user, uint256 amount);
    event Lent(address indexed lender, address indexed borrower, uint256 amount);
    event Repaid(address indexed borrower, address indexed lender, uint256 amount);

    // Deposit ETH into your balance
    function deposit() public payable {
        require(msg.value > 0, "Must deposit some ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Record that 'borrower' owes 'msg.sender' a certain amount
    function lend(address borrower, uint256 amount) public {
        require(borrower != msg.sender, "Cannot lend to yourself");
        require(amount > 0, "Amount must be greater than zero");

        debts[borrower][msg.sender] += amount;
        emit Lent(msg.sender, borrower, amount);
    }

    // Repay your debt to a lender
    function repay(address lender) public payable {
        require(msg.value > 0, "Repayment must be greater than zero");
        require(debts[msg.sender][lender] >= msg.value, "You don't owe that much");

        // Reduce the recorded debt
        debts[msg.sender][lender] -= msg.value;

        // Transfer ETH to the lender
        payable(lender).transfer(msg.value);

        emit Repaid(msg.sender, lender, msg.value);
    }

    // Check how much 'borrower' owes 'lender'
    function checkDebt(address borrower, address lender) public view returns (uint256) {
        return debts[borrower][lender];
    }

    // Check your own ETH balance
    function checkMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // Allow a user to withdraw their unused balance
    function withdraw(uint256 amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
