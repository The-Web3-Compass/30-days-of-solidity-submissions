// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleLending {
    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public borrowBalances;
    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    uint256 public interestRateBasisPoints = 500;
    uint256 public collateralFactorBasisPoints = 7500;
    uint256 public maxBorrowLimitPerUser = 10 ether;

    uint256 public totalDeposits;
    uint256 public totalBorrows;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    function deposit() external payable{
        require(msg.value > 0,"Deposit must be greater than zero");
        depositBalances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0,"Withdraw must be greater than zero");
        require(depositBalances[msg.sender] >= amount,"Not enough balance to withdraw");
        
        uint256 availableLiquidity = totalDeposits - totalBorrows;
        require(availableLiquidity >= amount,"Not enough liquidity in pool");
        
        depositBalances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdraw(msg.sender, amount);
    }

    function calculateInterestAccrued(address user) public view returns(uint256) {
        if (borrowBalances[user] == 0 || lastInterestAccrualTimestamp[user] == 0) {
            return borrowBalances[user];
        }
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);

        return borrowBalances[user] + interest;
    }

    function depositCollateral() external payable{
        require(msg.value > 0,"Collateral Deposit must be greater than zero");
        collateralBalances[msg.sender] += msg.value;

        emit CollateralDeposited(msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 amount) external {
        require(amount > 0,"Withdraw must be greater than zero");
        require(collateralBalances[msg.sender] >= amount,"Not enough balance to withdraw");

        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        
        if (borrowedAmount > 0) {
            uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;
            require(collateralBalances[msg.sender] - amount >= requiredCollateral,"Not enough collateral to withdraw");
        }

        collateralBalances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit CollateralWithdrawn(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        require(amount > 0,"Must borrow a positive amount");
        require(collateralBalances[msg.sender] > 0,"Must deposit collateral first");
        
        uint256 availableLiquidity = totalDeposits - totalBorrows;
        require(availableLiquidity >= amount,"Not enough liquidity in pool");

        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(msg.sender);

        require(currentDebt + amount <= maxBorrowAmount,"Exceeds collateral-based borrow limit");
        
        require(currentDebt + amount <= maxBorrowLimitPerUser,"Exceeds maximum borrow limit per user");

        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        totalBorrows += amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Borrow(msg.sender,amount);
    }

    function repay() external payable{
        require(msg.value > 0,"Must repay a positive amount");
        
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt > 0,"No debt to repay");

        uint256 amountToRepay = msg.value;
        uint256 refund = 0;
        
        if (amountToRepay > currentDebt) {
            refund = msg.value - currentDebt;
            amountToRepay = currentDebt;
        }

        uint256 principalRepaid = amountToRepay;
        if (principalRepaid > borrowBalances[msg.sender]) {
            principalRepaid = borrowBalances[msg.sender];
        }
        
        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        totalBorrows -= principalRepaid;

        if (refund > 0) {
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund transfer failed");
        }

        emit Repay(msg.sender, amountToRepay);
    }

    function getMaxBorrowAmount(address user) external view returns(uint256) {
        uint256 collateralBasedLimit = (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(user);
        uint256 remainingUserLimit = maxBorrowLimitPerUser > currentDebt ? maxBorrowLimitPerUser - currentDebt : 0;
        uint256 remainingCollateralLimit = collateralBasedLimit > currentDebt ? collateralBasedLimit - currentDebt : 0;
        
        return remainingUserLimit < remainingCollateralLimit ? remainingUserLimit : remainingCollateralLimit;
    }

    function getTotalLiquidity() external view returns(uint256) {
        return totalDeposits - totalBorrows;
    }

    function getUserDebt(address user) external view returns(uint256) {
        return calculateInterestAccrued(user);
    }

    function setMaxBorrowLimit(uint256 newLimit) external {
        maxBorrowLimitPerUser = newLimit;
    }
}