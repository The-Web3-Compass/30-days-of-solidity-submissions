// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLending {
    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public borrowBalances;
    mapping(address => uint256) public collateralBalances;  
    uint256 public interestRateBasisPoints = 500;
    uint256 public collateralFactorBasisPoints = 7500;
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Invalid deposit amount.");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Invalid withdrawal amount.");
        require(depositBalances[msg.sender] >= amount, "Insufficient balance.");
        depositBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount); //prevents reentrancy attacks
        emit Withdraw(msg.sender, amount);
    }

    function depositCollateral() external payable {
        require(msg.value > 0, "Invalid collateral amount.");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "Invalid collateral withdrawal amount.");
        
        uint256 collateralBalance = collateralBalances[msg.sender];
        require(collateralBalance >= amount, "Insufficient collateral balance.");
        uint256 minCollateral = (borrowBalances[msg.sender] + calculateInterestAccrued(msg.sender))
                                    * 10000 / collateralFactorBasisPoints;
        require(collateralBalance - amount >= minCollateral, "Insufficient collateral balance.");

        collateralBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "Invalid borrow amount.");
        require(address(this).balance >= amount, "Insufficient liquidity.");

        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 intendedBorrowAmount = borrowBalances[msg.sender] + calculateInterestAccrued(msg.sender) + amount;

        require(intendedBorrowAmount <= maxBorrowAmount, "Exceeds allowed borrow amount.");

        borrowBalances[msg.sender] = intendedBorrowAmount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;        
        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    }

    function repay() external payable {
        require(msg.value > 0, "Invalid repayment amount.");
        uint256 maxRepayAmount = calculateInterestAccrued(msg.sender) + borrowBalances[msg.sender];
        require(maxRepayAmount > 0, "No debt to repay.");
        if (msg.value < maxRepayAmount) 
            maxRepayAmount = msg.value;     
        payable(msg.sender).transfer(maxRepayAmount);
        
        borrowBalances[msg.sender] -= maxRepayAmount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        emit Repay(msg.sender, msg.value);
    }

    function calculateInterestAccrued(address user) public view returns (uint256) {
        uint256 interestAccrued = borrowBalances[user] * interestRateBasisPoints 
                                        * (block.timestamp - lastInterestAccrualTimestamp[user]) 
                                        / (10000 * 365 days);
        return interestAccrued;
    }

    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return collateralBalances[user] * collateralFactorBasisPoints / 10000;
    }

    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }
}