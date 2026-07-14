// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract EtherPiggyBank {
    error PiggyBank_InsufficientAmount();
    error PiggyBank_InsufficientBalance();
    error PiggyBank_AccountSuspended();
    error PiggyBank_NoAccount();
    error PiggyBank_Unauthorized();

    struct Account {
        uint256 id;
        uint256 balance;
        bool exists;
        bool isSuspended;
    }

    uint256 public accountTotal;
    uint256 public totalBalance;

    mapping(address => Account) public accounts; // Made public for easier access
    address private owner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert PiggyBank_Unauthorized();
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event AccountSuspended(address indexed account, bool suspended);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    function depositMoney() public payable {
        if (msg.value == 0) revert PiggyBank_InsufficientAmount();
        if (accounts[msg.sender].isSuspended) revert PiggyBank_AccountSuspended();

        Account storage currentAccount = accounts[msg.sender];
        if (!currentAccount.exists) {
            currentAccount.id = accountTotal++;
            currentAccount.exists = true;
        }
        
        currentAccount.balance += msg.value;
        totalBalance += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawMoney(uint256 amount) public {
        if (amount == 0) revert PiggyBank_InsufficientAmount();
        
        Account storage currentAccount = accounts[msg.sender];
        if (!currentAccount.exists) revert PiggyBank_NoAccount();
        if (currentAccount.isSuspended) revert PiggyBank_AccountSuspended();
        if (currentAccount.balance < amount) revert PiggyBank_InsufficientBalance();
        
        // Update state before external call
        totalBalance -= amount;
        currentAccount.balance -= amount;
        
        (bool success,) = payable(msg.sender).call{value: amount}("");
        
        if (!success) {
            totalBalance += amount;
            currentAccount.balance += amount;
            revert("Transfer failed");
        }
        
        emit Withdrawal(msg.sender, amount);
    }
    
    function getAccountBalance() external view returns (uint256) { 
        return accounts[msg.sender].balance;
    }

    function getOwner() external view returns(address) {
        return owner;
    }

    function getAccountDetails(address _account) 
        public view 
        returns (uint256 id, uint256 balance, bool exists, bool isSuspended) 
    {
        Account memory acc = accounts[_account]; // Use memory for read-only
        return (acc.id, acc.balance, acc.exists, acc.isSuspended);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner == address(0)) revert("Owner cannot be zero address");
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function suspendAccount(address _account, bool _isSuspended) public onlyOwner {
        if (!accounts[_account].exists) revert PiggyBank_NoAccount();
        accounts[_account].isSuspended = _isSuspended;
        emit AccountSuspended(_account, _isSuspended);
    }

    // Emergency withdrawal for owner - good to have!
    function emergencyWithdraw(uint256 amount) public onlyOwner {
        if (amount > address(this).balance) revert PiggyBank_InsufficientBalance();
        
        (bool success,) = payable(owner).call{value: amount}("");
        if (!success) revert("Transfer failed");
    }

    // Get contract's total ETH balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}