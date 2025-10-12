// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    // Personal Ether balance of each user
    mapping(address => uint256) public balances;

    // Nested mapping: oweBalances[debtor][creditor] = amount owed by debtor to creditor
    mapping(address => mapping(address => uint256)) public oweBalances;

    event Deposited(address indexed user, uint256 amount);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtSettled(address indexed debtor, address indexed creditor, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // Deposit Ether to your personal balance
    function deposit() external payable {
        require(msg.value > 0, "Must deposit positive amount");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Record a debt where msg.sender owes _creditor an amount
    function recordDebt(address _creditor, uint256 _amount) external {
        require(_creditor != msg.sender, "Cannot owe yourself");
        require(_amount > 0, "Debt amount must be positive");
        oweBalances[msg.sender][_creditor] += _amount;
        emit DebtRecorded(msg.sender, _creditor, _amount);
    }

    // Settle debt partially or fully, transferring Ether to creditor from your balance
    function settleDebt(address _creditor, uint256 _amount) external {
        require(_creditor != msg.sender, "Cannot settle with yourself");
        require(_amount > 0, "Settle amount must be positive");
        uint256 owed = oweBalances[msg.sender][_creditor];
        require(owed >= _amount, "Settle amount exceeds owed");
        require(balances[msg.sender] >= _amount, "Insufficient balance to settle");

        // Update balances and owed amounts
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        oweBalances[msg.sender][_creditor] -= _amount;

        emit DebtSettled(msg.sender, _creditor, _amount);
    }

    // Withdraw Ether from your balance to your wallet
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Withdraw amount must be positive");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    // View how much one address owes another
    function getOwedAmount(address _debtor, address _creditor) external view returns (uint256) {
        return oweBalances[_debtor][_creditor];
    }
}
