// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FriendIOU {
    // Track each user's deposited ETH balance
    mapping(address => uint256) public balances;
    
    // Track debts: debtor => creditor => amount owed
    mapping(address => mapping(address => uint256)) public debts;
    
    // Track who has outstanding debts to others
    mapping(address => bool) public hasOutstandingDebts;
    
    // Track total deposits in the contract
    uint256 public totalDeposits;

    event Deposited(address indexed user, uint256 amount);
    event DebtRecorded(
        address indexed debtor,
        address indexed creditor,
        uint256 amount
    );
    event DebtSettled(
        address indexed debtor,
        address indexed creditor,
        uint256 amount
    );
    event Withdrawn(address indexed user, uint256 amount);
    event DebtForgiven(
        address indexed creditor,
        address indexed debtor,
        uint256 amount
    );

    // Deposit ETH into your personal balance
    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0 ETH");

        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    // Record that someone owes you ETH
    function recordDebt(address debtor, uint256 amount) external {
        require(amount > 0, "Debt amount must be greater than 0");
        require(debtor != msg.sender, "You can't owe yourself");

        debts[debtor][msg.sender] += amount;
        hasOutstandingDebts[debtor] = true;

        emit DebtRecorded(debtor, msg.sender, amount);
    }

    // Settle a debt using your deposited balance
    function settleDebt(address creditor) external payable {
        uint256 amount = debts[msg.sender][creditor];
        require(amount > 0, "No debt to settle with this creditor");

        // Update state before transfer to prevent reentrancy
        debts[msg.sender][creditor] = 0;
        balances[msg.sender] -= amount;
        balances[creditor] += amount;

        checkOutstandingDebts(msg.sender);

        emit DebtSettled(msg.sender, creditor, amount);
    }

    // Forgive a debt (only creditor can forgive)
    function forgiveDebt(address debtor) external {
        uint256 amount = debts[debtor][msg.sender];
        require(amount > 0, "No debt to forgive");

        debts[debtor][msg.sender] = 0;

        checkOutstandingDebts(debtor);

        emit DebtForgiven(msg.sender, debtor, amount);
    }

    // Withdraw your available balance
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, amount);
    }

    // Check total debt you owe to a specific creditor
    function debtOwedTo(address creditor) external view returns (uint256) {
        return debts[msg.sender][creditor];
    }

    // Check total debt someone owes you
    function debtOwedBy(address debtor) external view returns (uint256) {
        return debts[debtor][msg.sender];
    }

    // Calculate your net worth (balance - debts)
    function checkOutstandingDebts(address user) private {
        hasOutstandingDebts[user] = false;
    }
}