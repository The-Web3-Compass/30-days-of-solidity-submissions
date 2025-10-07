//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title SimpleIOU
 * @dev A contract for managing IOUs (I Owe You) between friends
 * Features:
 * - Deposit ETH to personal balance
 * - Withdraw ETH from personal balance
 * - Record debts between users
 * - Settle debts by transferring from deposited balance
 * - Track who owes whom and how much
 */
contract SimpleIOU {
    // Mapping to track each user's deposited balance
    mapping(address => uint256) public balances;
    
    // Nested mapping to track debts
    // Example, debts[Alice][Bob] = 100 means Alice owes Bob 100 wei
    mapping(address => mapping(address => uint256)) public debts;
    
    // Events for tracking important actions
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtSettled(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtPaidPartially(address indexed debtor, address indexed creditor, uint256 amount, uint256 remaining);
    
    // Deposit ETH into the contract and add to the sender's balance
    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0");
        
        balances[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw ETH from personal balance
     * @param _amount The amount to withdraw in wei
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        // Transfer ETH to the user
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, _amount);
    }
    
    /**
     * @dev Record a new debt or add to existing debt
     * @param _creditor The address of the person you owe money to
     * @param _amount The amount you owe in wei
     * 
     * Example: If Alice calls recordDebt(Bob, 100), it means Alice acknowledges 
     * she owes Bob 100 wei
     */
    function recordDebt(address _creditor, uint256 _amount) external {
        require(_creditor != address(0), "Invalid creditor address");
        require(_creditor != msg.sender, "Cannot owe yourself");
        require(_amount > 0, "Debt amount must be greater than 0");
        
        // Add to existing debt
        debts[msg.sender][_creditor] += _amount;
        
        emit DebtRecorded(msg.sender, _creditor, _amount);
    }
    
    /**
     * @dev Settle a debt using your deposited balance
     * @param _creditor The address of the person you owe money to
     * @param _amount The amount to pay back in wei
     * 
     * This transfers funds from your balance to the creditor's balance
     */
    function settleDebt(address _creditor, uint256 _amount) external {
        require(_creditor != address(0), "Invalid creditor address");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] > 0, "No debt to this creditor");
        require(balances[msg.sender] >= _amount, "Insufficient balance to settle debt");

        uint256 currentDebt = debts[msg.sender][_creditor];
        uint256 amountToSettle = _amount;

        // If paying more than owed, only settle the actual debt
        if (_amount > currentDebt) {
            amountToSettle = currentDebt;
        }
        
        // Update balances
        balances[msg.sender] -= amountToSettle;
        balances[_creditor] += amountToSettle;
        
        // Update debt
        debts[msg.sender][_creditor] -= amountToSettle;

        if (debts[msg.sender][_creditor] == 0) {
            emit DebtSettled(msg.sender, _creditor, amountToSettle);
        } else {
            emit DebtPaidPartially(msg.sender, _creditor, amountToSettle, debts[msg.sender][_creditor]);
        }
    }
    
    /**
     * @dev Get the amount you owe to a specific creditor
     * @param _creditor The address of the creditor
     * @return The amount owed in wei
     */
    function getDebtTo(address _creditor) external view returns (uint256) {
        return debts[msg.sender][_creditor];
    }
    
    /**
     * @dev Get the amount someone owes to you
     * @param _debtor The address of the debtor
     * @return The amount they owe you in wei
     */
    function getDebtFrom(address _debtor) external view returns (uint256) {
        return debts[_debtor][msg.sender];
    }
    
    /**
     * @dev Get your current balance in the contract
     * @return Your balance in wei
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Check the debt between any two addresses (public view)
     * @param _debtor The address of the debtor
     * @param _creditor The address of the creditor
     * @return The amount debtor owes to creditor in wei
     */
    function checkDebt(address _debtor, address _creditor) external view returns (uint256) {
        return debts[_debtor][_creditor];
    }
    
    /**
     * @dev Fallback function to accept ETH deposits
     * Any ETH sent directly to the contract will be added to sender's balance
     */
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}