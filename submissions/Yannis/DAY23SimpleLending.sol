// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


contract SimpleLending {
    
    mapping(address => uint256) public depositBalances;
    
    
    mapping(address => uint256) public borrowBalances;
    
    
    mapping(address => uint256) public collateralBalances;
    
    
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    
    uint256 public constant INTEREST_RATE_BASIS_POINTS = 500;
    
    
    uint256 public constant COLLATERAL_FACTOR_BASIS_POINTS = 7500;
    
    
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Liquidation(address indexed user, address indexed liquidator, uint256 amount);

    
    error InvalidAmount();
    error InsufficientBalance();
    error InsufficientCollateral();
    error InsufficientLiquidity();
    error ExceedsBorrowLimit();
    error NoDebtToRepay();
    error TransferFailed();
    error LoanNotLiquidatable();

    
    function deposit() external payable {
        if (msg.value == 0) {
            revert InvalidAmount();
        }

        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    
    function withdraw(uint256 amount) external {
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (depositBalances[msg.sender] < amount) {
            revert InsufficientBalance();
        }

        
        _checkWithdrawalSafety(msg.sender, amount);

        depositBalances[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
        
        emit Withdraw(msg.sender, amount);
    }

    
    function depositCollateral() external payable {
        if (msg.value == 0) {
            revert InvalidAmount();
        }

        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    
    function withdrawCollateral(uint256 amount) external {
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (collateralBalances[msg.sender] < amount) {
            revert InsufficientCollateral();
        }

        
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        
        
        uint256 requiredCollateral = (currentDebt * 10000) / COLLATERAL_FACTOR_BASIS_POINTS;
        
        
        if (collateralBalances[msg.sender] - amount < requiredCollateral) {
            revert InsufficientCollateral();
        }

        collateralBalances[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
        
        emit CollateralWithdrawn(msg.sender, amount);
    }

    
    function borrow(uint256 amount) external {
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (address(this).balance < amount) {
            revert InsufficientLiquidity();
        }

        
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * COLLATERAL_FACTOR_BASIS_POINTS) / 10000;
        
        
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        
        
        if (currentDebt + amount > maxBorrowAmount) {
            revert ExceedsBorrowLimit();
        }

    
        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
        
        emit Borrow(msg.sender, amount);
    }

    
    function repay() external payable {
        if (msg.value == 0) {
            revert InvalidAmount();
        }

        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        if (currentDebt == 0) {
            revert NoDebtToRepay();
        }

        uint256 amountToRepay = msg.value;
        uint256 refundAmount = 0;

        
        if (amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            refundAmount = msg.value - currentDebt;
        }

        
        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        
        if (refundAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
            if (!success) {
                revert TransferFailed();
            }
        }

        emit Repay(msg.sender, amountToRepay);
    }

    
    function calculateInterestAccrued(address user) public view returns (uint256) {
        if (borrowBalances[user] == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        if (timeElapsed == 0) {
            return borrowBalances[user];
        }

        
        uint256 interest = (borrowBalances[user] * INTEREST_RATE_BASIS_POINTS * timeElapsed) / 
                          (10000 * SECONDS_PER_YEAR);

        return borrowBalances[user] + interest;
    }

    
    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * COLLATERAL_FACTOR_BASIS_POINTS) / 10000;
    }

    
    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }

    
    function getHealthFactor(address user) external view returns (uint256) {
        uint256 currentDebt = calculateInterestAccrued(user);
        if (currentDebt == 0) {
            return type(uint256).max; 
        }

        uint256 maxBorrowValue = (collateralBalances[user] * COLLATERAL_FACTOR_BASIS_POINTS) / 10000;
        return (maxBorrowValue * 10000) / currentDebt; 
    }

    
    function getUserInfo(address user) external view returns (
        uint256 depositBalance,
        uint256 collateralBalance,
        uint256 currentDebt,
        uint256 maxBorrow,
        uint256 healthFactor
    ) {
        depositBalance = depositBalances[user];
        collateralBalance = collateralBalances[user];
        currentDebt = calculateInterestAccrued(user);
        maxBorrow = (collateralBalance * COLLATERAL_FACTOR_BASIS_POINTS) / 10000;
        
        if (currentDebt == 0) {
            healthFactor = type(uint256).max;
        } else {
            healthFactor = (maxBorrow * 10000) / currentDebt;
        }
    }

    
    function liquidate(address user) external {
        uint256 currentDebt = calculateInterestAccrued(user);
        uint256 maxBorrowValue = (collateralBalances[user] * COLLATERAL_FACTOR_BASIS_POINTS) / 10000;
        
        
        if (maxBorrowValue >= currentDebt) {
            revert LoanNotLiquidatable();
        }

        
        uint256 collateralToLiquidate = (currentDebt * 10000) / COLLATERAL_FACTOR_BASIS_POINTS;
        
        require(collateralToLiquidate <= collateralBalances[user], "Insufficient collateral");
        
        
        borrowBalances[user] = 0;
        collateralBalances[user] -= collateralToLiquidate;
        lastInterestAccrualTimestamp[user] = block.timestamp;

        
        (bool success, ) = payable(msg.sender).call{value: collateralToLiquidate}("");
        if (!success) {
            revert TransferFailed();
        }

        emit Liquidation(user, msg.sender, collateralToLiquidate);
    }

    
    function _checkWithdrawalSafety(address user, uint256 amount) internal view {
        uint256 currentDebt = calculateInterestAccrued(user);
        if (currentDebt > 0) {
            
            uint256 remainingDeposit = depositBalances[user] - amount;
            uint256 requiredDeposit = (currentDebt * 10000) / COLLATERAL_FACTOR_BASIS_POINTS;
            
            if (remainingDeposit < requiredDeposit) {
                revert InsufficientBalance();
            }
        }
    }

    
    receive() external payable {}
}