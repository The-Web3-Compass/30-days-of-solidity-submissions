// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalPiggyBank {
    // Track each user's balance
    mapping(address => uint256) public balances;
    
    // Track total deposits in the contract
    uint256 public totalDeposits;
    
    // Track total withdrawals from the contract
    uint256 public totalWithdrawals;
    
    // Events to log transactions
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    // Deposit function - allows users to send ETH to their piggy bank
    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0 ETH");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
    
    // Withdraw function - allows users to withdraw their ETH
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Update state before sending to prevent reentrancy
        balances[msg.sender] -= amount;
        totalWithdrawals += amount;
        
        // Send Ether to the user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    // Check user's balance
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    // Check contract's total balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}