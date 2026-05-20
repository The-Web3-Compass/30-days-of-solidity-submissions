// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LendingPool {

    address public owner;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;
    mapping(address => uint256) public collateral;

    uint256 public interestRate = 5; // 5% interest

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event CollateralAdded(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    /*
     * Deposit funds (lend to pool)
     */
    function deposit() external payable {
        require(msg.value > 0, "Send ETH");

        deposits[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    /*
     * Add collateral
     */
    function addCollateral() external payable {
        require(msg.value > 0, "Send ETH");

        collateral[msg.sender] += msg.value;

        emit CollateralAdded(msg.sender, msg.value);
    }

    /*
     * Borrow funds (requires collateral)
     */
    function borrow(uint256 _amount) external {

        require(collateral[msg.sender] >= _amount * 2, "Insufficient collateral"); // 200% collateral
        require(address(this).balance >= _amount, "Not enough liquidity");

        borrows[msg.sender] += _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Borrowed(msg.sender, _amount);
    }

    /*
     * Repay borrowed amount with interest
     */
    function repay() external payable {

        uint256 borrowed = borrows[msg.sender];
        require(borrowed > 0, "No active loan");

        uint256 interest = (borrowed * interestRate) / 100;
        uint256 total = borrowed + interest;

        require(msg.value >= total, "Insufficient repayment");

        borrows[msg.sender] = 0;

        emit Repaid(msg.sender, msg.value);
    }

    /*
     * Withdraw deposit (lender)
     */
    function withdrawDeposit(uint256 _amount) external {
        require(deposits[msg.sender] >= _amount, "Not enough balance");

        deposits[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
    }

    /*
     * View total debt with interest
     */
    function getTotalDebt(address user) external view returns (uint256) {
        uint256 borrowed = borrows[user];
        uint256 interest = (borrowed * interestRate) / 100;
        return borrowed + interest;
    }
}