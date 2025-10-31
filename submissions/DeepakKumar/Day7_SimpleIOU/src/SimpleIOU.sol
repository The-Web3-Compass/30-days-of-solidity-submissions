// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleIOU {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed borrower, address indexed lender, uint256 amount);
    event Repaid(address indexed borrower, address indexed lender, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // Deposit ETH into your balance
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Borrow ETH from a friend (create IOU)
    function borrow(address lender, uint256 amount) external {
        require(lender != msg.sender, "Cannot borrow from yourself");
        require(balances[lender] >= amount, "Lender does not have enough balance");

        debts[msg.sender][lender] += amount;
        balances[lender] -= amount;
        balances[msg.sender] += amount;

        emit Borrowed(msg.sender, lender, amount);
    }

    // Repay ETH owed to a lender
    function repay(address lender) external payable {
        uint256 debt = debts[msg.sender][lender];
        require(debt > 0, "No debt found");
        require(msg.value == debt, "Send exact repayment amount");

        debts[msg.sender][lender] = 0;
        balances[lender] += msg.value;

        emit Repaid(msg.sender, lender, msg.value);
    }

    // Withdraw ETH from personal balance
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    // Check total debt between borrower and lender
    function getDebt(address borrower, address lender) external view returns (uint256) {
        return debts[borrower][lender];
    }

    // Direct ETH receiver — handles plain transfers
    receive() external payable {
        require(msg.value > 0, "Cannot send 0 ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
