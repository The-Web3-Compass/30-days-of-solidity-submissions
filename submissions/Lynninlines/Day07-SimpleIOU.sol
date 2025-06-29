// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {
    mapping(address => uint256) public balances;
    
    mapping(address => mapping(address => uint256)) public debts;
    
    event Deposit(address indexed user, uint256 amount);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtSettled(address indexed debtor, address indexed creditor, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function createDebt(address creditor, uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        require(msg.sender != creditor, "Cannot owe yourself");
        
        debts[msg.sender][creditor] += amount;
        emit DebtRecorded(msg.sender, creditor, amount);
    }

    function settleDebt(address creditor, uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        require(debts[msg.sender][creditor] >= amount, "Debt too small");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        debts[msg.sender][creditor] -= amount;
        balances[msg.sender] -= amount;
        balances[creditor] += amount;
        
        emit DebtSettled(msg.sender, creditor, amount);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
