// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SimpleIOU
/// @notice A contract for a private group of friends to track ETH borrowing and lending
contract SimpleIOU {
    /// @notice Tracks ETH balance of each user
    mapping(address => uint256) public balances;

    /// @notice Tracks debts: debtor => creditor => amount
    mapping(address => mapping(address => uint256)) public debts;

    /// @notice Emitted when a user deposits ETH
    event Deposited(address indexed user, uint256 amount);
    /// @notice Emitted when a debt is recorded
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    /// @notice Emitted when a debt is settled
    event DebtSettled(address indexed debtor, address indexed creditor, uint256 amount);

    /// @notice Allows a user to deposit ETH into the contract
    /// @dev Updates user's balance; emits Deposited event
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Records a debt from debtor to creditor
    /// @dev Debtor must have sufficient balance; updates debts mapping; emits DebtRecorded event
    /// @param creditor The address of the user who is owed
    /// @param amount The amount of ETH to be recorded as debt
    function recordDebt(address creditor, uint256 amount) external {
        require(creditor != msg.sender, "Cannot owe yourself");
        require(creditor != address(0), "Invalid creditor address");
        require(amount > 0, "Debt amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        debts[msg.sender][creditor] += amount;
        emit DebtRecorded(msg.sender, creditor, amount);
    }

    /// @notice Settles a debt by transferring ETH to the creditor
    /// @dev Deducts debt amount from debtor's debt and transfers ETH; emits DebtSettled event
    /// @param creditor The address of the creditor to settle with
    /// @param amount The amount of ETH to settle
    function settleDebt(address creditor, uint256 amount) external {
        require(creditor != msg.sender, "Cannot settle debt with yourself");
        require(amount > 0, "Settlement amount must be greater than 0");
        require(debts[msg.sender][creditor] >= amount, "Insufficient debt to settle");
        require(balances[msg.sender] >= amount, "Insufficient balance to settle");

        debts[msg.sender][creditor] -= amount;
        balances[msg.sender] -= amount;
        balances[creditor] += amount;

        emit DebtSettled(msg.sender, creditor, amount);
    }

    /// @notice Allows a user to withdraw their available ETH balance
    /// @dev Transfers ETH to user; updates balance
    /// @param amount The amount of ETH to withdraw
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Retrieves the debt amount owed by debtor to creditor
    /// @param debtor The address of the debtor
    /// @param creditor The address of the creditor
    /// @return The amount of ETH owed
    function getDebt(address debtor, address creditor) external view returns (uint256) {
        return debts[debtor][creditor];
    }
}
