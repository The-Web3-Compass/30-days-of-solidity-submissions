// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLending {
    // 银行余额
    mapping(address => uint256) public depositBalances;

    // Borrowed amounts for each user
    mapping(address => uint256) public borrowBalances;

    // 抵押的ETH数量
    mapping(address => uint256) public collateralBalances;

    // Interest rate in basis points (1/100 of a percent)
    //一个基点 = 0.01% 
    // 500 basis points = 5% interest
    //借钱利率
    uint256 public interestRateBasisPoints = 500;

    // Collateral factor in basis points (e.g., 7500 = 75%)
    // Determines how much you can borrow against your collateral
    //根据抵押品价值可以借多少
    uint256 public collateralFactorBasisPoints = 7500;

    // Timestamp of last interest accrual
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    //当用户将ETH锁定作为抵押品时发出
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    
    //存款
    function deposit() external payable {
        require(msg.value > 0, "Must deposit a positive amount");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    //取款

    function withdraw(uint256 amount) external {
        require(amount > 0, "Must withdraw a positive amount");
        require(depositBalances[msg.sender] >= amount, "Insufficient balance");
        depositBalances[msg.sender] -= amount;
        //payable(...) — 将地址转化为可接收ETH的地址
        //Solidity要求对可支付地址调用.transfer()
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    //锁定抵押的ETH

    function depositCollateral() external payable {
        require(msg.value > 0, "Must deposit a positive amount as collateral");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    //拿回你锁定的ETH

    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "Must withdraw a positive amount");
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");

        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;

        require(
            collateralBalances[msg.sender] - amount >= requiredCollateral,
            "Withdrawal would break collateral ratio"
        );

        collateralBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    //借入ETH

    function borrow(uint256 amount) external {
        require(amount > 0, "Must borrow a positive amount");
        require(address(this).balance >= amount, "Not enough liquidity in the pool");

        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(msg.sender);

        require(currentDebt + amount <= maxBorrowAmount, "Exceeds allowed borrow amount");

        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    }

    //还款

    function repay() external payable {
        require(msg.value > 0, "Must repay a positive amount");

        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt > 0, "No debt to repay");

        uint256 amountToRepay = msg.value;
        if (amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt);
        }

        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);
    }

    //即时利息计算器

    function calculateInterestAccrued(address user) public view returns (uint256) {
        //没有贷款，没有利息
        if (borrowBalances[user] == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];//已过去多少时间
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);//利息计算

        return borrowBalances[user] + interest;//返回总债务
    }

    //计算根据保证金可以借多少ETH

    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }

    //当前借贷池有多少ETH

    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }
}

