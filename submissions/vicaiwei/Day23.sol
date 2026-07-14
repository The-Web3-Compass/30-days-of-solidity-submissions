// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleLending
 * @dev A minimal ETH lending/borrowing pool with on-demand interest accrual
 */
contract SimpleLending {
    // User balances
    mapping(address => uint256) public depositBalances;    // Liquid deposits
    mapping(address => uint256) public borrowBalances;     // Principal owed
    mapping(address => uint256) public collateralBalances; // Locked collateral

    // Parameters
    // 500 basis points = 5% APR
    uint256 public interestRateBasisPoints = 500;
    // 7500 basis points = 75% LTV
    uint256 public collateralFactorBasisPoints = 7500;

    // Last timestamp used for interest accrual per user
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    // Deposit liquid ETH into the pool
    function deposit() external payable {
        require(msg.value > 0, "Deposit > 0");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw deposited ETH
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdraw > 0");
        require(depositBalances[msg.sender] >= amount, "Insufficient deposit");
        depositBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // Lock ETH as collateral to enable borrowing
    function depositCollateral() external payable {
        require(msg.value > 0, "Collateral > 0");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    // Withdraw collateral if still safely collateralized after withdrawal
    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "Withdraw > 0");
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");

        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;

        require(
            collateralBalances[msg.sender] - amount >= requiredCollateral,
            "Unsafe: violates collateral ratio"
        );

        collateralBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    // Borrow ETH against locked collateral
    function borrow(uint256 amount) external {
        require(amount > 0, "Borrow > 0");
        require(address(this).balance >= amount, "Insufficient pool liquidity");

        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(msg.sender);

        require(currentDebt + amount <= maxBorrowAmount, "Exceeds borrow limit");

        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    }

    // Repay debt; refunds any excess sent
    function repay() external payable {
        require(msg.value > 0, "Repay > 0");

        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt > 0, "No debt");

        uint256 amountToRepay = msg.value;

        if (amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            // Refund excess
            payable(msg.sender).transfer(msg.value - currentDebt);
        }

        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);
    }

    // Returns principal + linear accrued interest since last accrual timestamp
    function calculateInterestAccrued(address user) public view returns (uint256) {
        uint256 principal = borrowBalances[user];
        if (principal == 0) return 0;

        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        uint256 interest = (principal * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);

        return principal + interest;
    }

    // Upper bound based only on collateral and collateral factor
    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }

    // Pool liquidity (contract ETH balance)
    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }
}