// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Day11 Ownable.sol";


contract VaultMaster is Ownable {
   
    struct VaultStats {
        uint256 totalDeposited;     // 总存入金额
        uint256 totalWithdrawn;     // 总提取金额
        uint256 depositCount;       // 存款次数
        uint256 withdrawCount;      // 提款次数
        uint256 createdAt;          // 创建时间
    }
    
    VaultStats public vaultStats;
    
    mapping(address => uint256) public deposits;
    
    address[] public depositors;
    
    event Deposit(
        address indexed depositor, 
        uint256 amount, 
        uint256 timestamp,
        uint256 newBalance
    );
    
    event Withdrawal(
        address indexed owner,
        address indexed recipient, 
        uint256 amount, 
        uint256 timestamp,
        uint256 remainingBalance
    );
    
    event VaultCreated(
        address indexed owner,
        uint256 timestamp
    );
    
    error InsufficientBalance(uint256 requested, uint256 available);
    error InvalidAmount();
    error InvalidRecipient(address recipient);
    error NoFundsToWithdraw();

    constructor() {
       
        vaultStats = VaultStats({
            totalDeposited: 0,
            totalWithdrawn: 0,
            depositCount: 0,
            withdrawCount: 0,
            createdAt: block.timestamp
        });
        
        emit VaultCreated(owner(), block.timestamp);
    }

    receive() external payable {
        deposit();
    }
    
    /**
     * @dev 回退函数 - 处理带有数据的 ETH 转账
     */
    fallback() external payable {
        deposit();
    }
   
    function deposit() public payable {
        // 验证存款金额大于 0
        if (msg.value == 0) {
            revert InvalidAmount();
        }
       
        if (deposits[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
     
        deposits[msg.sender] += msg.value;
  
        vaultStats.totalDeposited += msg.value;
        vaultStats.depositCount += 1;
 
        emit Deposit(
            msg.sender, 
            msg.value, 
            block.timestamp,
            address(this).balance
        );
    }

    function withdraw(uint256 amount, address payable recipient) 
        external 
        onlyOwner  // 使用继承的 onlyOwner 修饰符
    {
    
        if (amount == 0) {
            revert InvalidAmount();
        }
    
        if (recipient == address(0)) {
            revert InvalidRecipient(recipient);
        }
   
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) {
            revert NoFundsToWithdraw();
        }
        
        if (amount > contractBalance) {
            revert InsufficientBalance(amount, contractBalance);
        }
        
        vaultStats.totalWithdrawn += amount;
        vaultStats.withdrawCount += 1;
    
        recipient.transfer(amount);
    
        emit Withdrawal(
            msg.sender,
            recipient, 
            amount, 
            block.timestamp,
            address(this).balance
        );
    }
  
    function withdrawAll(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        
        if (balance == 0) {
            revert NoFundsToWithdraw();
        }
       
        if (recipient == address(0)) {
            revert InvalidRecipient(recipient);
        }
  
        vaultStats.totalWithdrawn += balance;
        vaultStats.withdrawCount += 1;

        recipient.transfer(balance);
  
        emit Withdrawal(
            msg.sender,
            recipient, 
            balance, 
            block.timestamp,
            address(this).balance
        );
    }
    
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        
        if (balance == 0) {
            revert NoFundsToWithdraw();
        }
        
        vaultStats.totalWithdrawn += balance;
        vaultStats.withdrawCount += 1;
        
        payable(owner()).transfer(balance);
        
        emit Withdrawal(
            msg.sender,
            owner(), 
            balance, 
            block.timestamp,
            address(this).balance
        );
    }
    
    function getBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }
    
    function getDepositorBalance(address depositor) external view returns (uint256 depositAmount) {
        return deposits[depositor];
    }

    function getDepositorsCount() external view returns (uint256 count) {
        return depositors.length;
    }

    function getDepositorAt(uint256 index) external view returns (address depositorAddress) {
        require(index < depositors.length, "Index out of bounds");
        return depositors[index];
    }
    

    function getVaultStats() external view returns (
        uint256 totalDeposited,
        uint256 totalWithdrawn,
        uint256 currentBalance,
        uint256 depositCount,
        uint256 withdrawCount,
        uint256 depositorsCount,
        uint256 createdAt
    ) {
        return (
            vaultStats.totalDeposited,
            vaultStats.totalWithdrawn,
            address(this).balance,
            vaultStats.depositCount,
            vaultStats.withdrawCount,
            depositors.length,
            vaultStats.createdAt
        );
    }
 
    function getAllDepositors() external view returns (address[] memory depositorsList) {
        return depositors;
    }
}