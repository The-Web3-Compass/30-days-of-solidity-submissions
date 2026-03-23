// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* Errors */
error Bank__UserCantDepositZeroAmount();
error Bank__UserCantWithdrawZeroAmount();
error Bank__InsufficientBalance(uint256 available, uint256 required);
error Bank__TransferFailed();
error Bank__InvalidAddress(address receiver);
error Bank__UnauthorizedAccount(address nonOwner);

contract Bank {
    /* State Variables Start */
    mapping(address => uint256) private s_addressToBalance;
    address private s_owner;
    uint256 private s_totalBankBalance;
    /* State Variables End */

    /* Modifiers Start */
    modifier checkZeroAddress(address receiver) {
        if (receiver == address(0)) revert Bank__InvalidAddress(receiver);
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert Bank__UnauthorizedAccount(msg.sender);
        _;
    }

    /* Modifiers End */

    /* Events */
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event TransferTo(address indexed sender, address indexed receiver, uint256 amount);
    event TransferInternal(address indexed sender, address indexed receiver, uint256 amount);
    event TransferContractOwnership(address indexed oldOwner, address indexed newOwner);
    /* Functions Start */

    constructor() {
        address oldOwner = s_owner;
        s_owner = msg.sender;
        emit TransferContractOwnership(oldOwner, s_owner);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        address depositor = msg.sender;
        uint256 depositAmount = msg.value;

        if (depositAmount == 0) revert Bank__UserCantDepositZeroAmount();

        s_addressToBalance[depositor] += depositAmount;
        s_totalBankBalance += depositAmount;

        emit Deposit(depositor, depositAmount);
    }

    function withdraw(uint256 amount) public {
        address withdrawer = msg.sender;
        uint256 withdrawerBalance = s_addressToBalance[withdrawer];
        // uint256 depositTime;

        if (amount == 0) revert Bank__UserCantWithdrawZeroAmount();

        if (amount > withdrawerBalance || withdrawerBalance == 0) {
            revert Bank__InsufficientBalance(withdrawerBalance, amount);
        }

        s_addressToBalance[withdrawer] = withdrawerBalance - amount;
        s_totalBankBalance -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert Bank__TransferFailed();

        emit Withdraw(msg.sender, amount);
    }

    function transferTo(address receiver, uint256 amount) public checkZeroAddress(receiver) {
        address sender = msg.sender;
        uint256 senderBalance = s_addressToBalance[sender];

        if (amount == 0) revert Bank__UserCantWithdrawZeroAmount();

        if (amount > senderBalance || senderBalance == 0) {
            revert Bank__InsufficientBalance(senderBalance, amount);
        }

        s_addressToBalance[sender] = senderBalance - amount;
        s_totalBankBalance -= amount;

        (bool success,) = payable(receiver).call{value: amount}("");
        if (!success) revert Bank__TransferFailed();

        emit TransferTo(sender, receiver, amount);
    }

    function transferInternal(address receiver, uint256 amount) public checkZeroAddress(receiver) {
        address sender = msg.sender;
        uint256 senderBalance = s_addressToBalance[msg.sender];

        if (amount == 0) revert Bank__UserCantWithdrawZeroAmount();
        if (amount > senderBalance) revert Bank__InsufficientBalance(senderBalance, amount);

        s_addressToBalance[sender] = senderBalance - amount;
        s_addressToBalance[receiver] += amount;

        emit TransferInternal(sender, receiver, amount);
    }

    function transferContractOwnership(address newOwner) public onlyOwner {
        address oldOwner = s_owner;

        if (newOwner == address(0)) revert Bank__InvalidAddress(newOwner);

        s_owner = newOwner;

        emit TransferContractOwnership(oldOwner, newOwner);
    }

    function getTotalBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function getBalance(address user) public view returns (uint256) {
        return s_addressToBalance[user];
    }

    function getCurrentOwner() public view returns (address) {
        return s_owner;
    }

    /* Functions End */
}
