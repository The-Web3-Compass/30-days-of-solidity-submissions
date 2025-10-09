// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title SimpleIOU
 * @dev A simple IOU contract where users can deposit Ether, record debts to others, and repay those debts on-chain.
 * Tracks personal balances and nested debt relationships using mappings.
 * Demonstrates `payable`, Ether transfers with `call`, and validation with `require`.
 */


contract SimpleIOU {
    mapping(address => uint256) public balances;
    
    mapping(address => mapping(address => uint256)) public debts;
    
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH to deposit");
        balances[msg.sender] += msg.value;
    }
    
    function recordDebt(address to, uint256 amount) external {
        require(to != address(0), "Invalid creditor address");
        require(amount > 0, "Amount must be positive");
        require(to != msg.sender, "Cannot owe yourself");
        
        debts[msg.sender][to] += amount;
    }
    
    function repayDebt(address to, uint256 amount) external payable {
        require(to != address(0), "Invalid creditor address");
        require(amount > 0, "Amount must be positive");
        require(debts[msg.sender][to] >= amount, "Repay amount exceeds debt");
        require(msg.value == amount, "Send ETH equal to repay amount");
        require(balances[to] + amount >= balances[to], "Overflow error");
        
        debts[msg.sender][to] -= amount;
        
        balances[to] += amount;
        
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    function getDebt(address debtor, address creditor) external view returns (uint256) {
        return debts[debtor][creditor];
    }
}
