// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeFiLending {
    // Structs
    struct Loan {
        uint collateralAmount;
        uint borrowedAmount;
        uint startTime;
    }

    // State variables
    mapping(address => uint) public deposits;
    mapping(address => Loan) public loans;
    uint public totalDeposits;
    uint public totalBorrowed;
    
    // Interest and risk parameters
    uint public constant SECONDS_PER_YEAR = 31536000;
    uint public baseRate = 50000000000000000; // 5% annual base rate (in wei)
    uint public utilizationMultiplier = 100000000000000000; // 10% slope (in wei)
    uint public collateralFactor = 150; // 150% over-collateralization
    uint public liquidationThreshold = 125; // 125% collateral ratio triggers liquidation

    // Events
    event Deposited(address indexed user, uint amount);
    event Borrowed(address indexed user, uint amount);
    event Repaid(address indexed user, uint amount);
    event Liquidated(address indexed user, address liquidator, uint repaid, uint collateralSeized);

    // Deposit assets to lend
    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Withdraw deposited assets
    function withdraw(uint amount) external {
        require(amount <= deposits[msg.sender], "Insufficient deposit");
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Borrow against collateral
    function borrow(uint amount) external {
        require(loans[msg.sender].collateralAmount > 0, "No collateral");
        uint borrowable = (loans[msg.sender].collateralAmount * collateralFactor) / 100;
        require(borrowable >= amount + loans[msg.sender].borrowedAmount, "Exceeds borrow limit");
        require(amount <= address(this).balance - totalBorrowed, "Insufficient liquidity");

        loans[msg.sender].borrowedAmount += amount;
        loans[msg.sender].startTime = block.timestamp;
        totalBorrowed += amount;
        payable(msg.sender).transfer(amount);
        emit Borrowed(msg.sender, amount);
    }

    // Add collateral
    function addCollateral() external payable {
        loans[msg.sender].collateralAmount += msg.value;
    }

    // Repay loan
    function repay() external payable {
        uint debt = calculateDebt(msg.sender);
        require(msg.value >= debt, "Insufficient repayment");
        
        uint excess = msg.value - debt;
        loans[msg.sender].borrowedAmount = 0;
        loans[msg.sender].startTime = 0;
        totalBorrowed -= debt;
        
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
        emit Repaid(msg.sender, debt);
    }

    // Liquidate undercollateralized position
    function liquidate(address borrower) external payable {
        uint debt = calculateDebt(borrower);
        uint collateralValue = loans[borrower].collateralAmount;
        uint collateralRatio = (collateralValue * 100) / debt;
        
        require(collateralRatio < liquidationThreshold, "Position not liquidatable");
        require(msg.value >= debt, "Insufficient repayment");

        uint collateralSeized = (debt * 105) / 100; // 5% liquidation bonus
        loans[borrower].borrowedAmount = 0;
        loans[borrower].collateralAmount = 0;
        totalBorrowed -= debt;
        
        payable(msg.sender).transfer(collateralSeized);
        emit Liquidated(borrower, msg.sender, debt, collateralSeized);
    }

    // Calculate debt with interest
    function calculateDebt(address borrower) public view returns (uint) {
        Loan memory loan = loans[borrower];
        if (loan.borrowedAmount == 0) return 0;
        
        uint utilization = (totalBorrowed * 1e18) / totalDeposits;
        uint borrowRate = baseRate + (utilization * utilizationMultiplier) / 1e18;
        uint interest = (loan.borrowedAmount * borrowRate * (block.timestamp - loan.startTime)) / SECONDS_PER_YEAR;
        
        return loan.borrowedAmount + interest;
    }

    // Helper: Check collateral ratio
    function collateralRatio(address borrower) public view returns (uint) {
        if (loans[borrower].borrowedAmount == 0) return 0;
        return (loans[borrower].collateralAmount * 100) / calculateDebt(borrower);
    }
}