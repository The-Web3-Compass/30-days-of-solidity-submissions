// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// DeFi
contract SimpleLending{
    // 基本信息
    mapping(address => uint256) public depositBalances; // 用户存入借贷池的 ETH 数量
    mapping(address => uint256) public borrowBalances; // 用户从池中借了多少 ETH
    mapping(address => uint256) public collateralBalances;//用户提供的作为抵押的 ETH 数量
    mapping(address => uint256) public lastInterestAccrualTimestamp;//户上次计算利息的时间

    //金融规则
    //  协议如何赚取收益
    uint256 public interestRateBasisPoints = 500;         // 5% 每年利率
    // 协议如何保持安全:该变量决定了根据抵押品价值可以借多少。
    uint256 public collateralFactorBasisPoints = 7500;    // 75% loan-to-value (LTV) 被允许借入的最大金额

    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    // 存钱
    function deposit() external payable {
        require(msg.value > 0, "Must deposit a positive amount");

        depositBalances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }
    // 取钱
    function withdraw(uint256 amount) external {
        require(amount > 0, "Must withdraw a positive amount");
        // 是否有足够的 ETH，DeFi 不允许透支 
        require(depositBalances[msg.sender] >= amount, "Insufficient balance");
       
        depositBalances[msg.sender] -= amount;
        // 下面一行实际上将真实的 ETH 转回用户的钱包。
        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    // 计算利润
    function calculateInterestAccrued(address user) public view returns (uint256) {
        if (borrowBalances[user] == 0) {
            return 0;
        }

        // 计算已过去多少时间
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        // 应用利息公式
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);

        return borrowBalances[user] + interest;
    }

    // 将 ETH 锁定作为抵押品，以便日后借款
    function depositCollateral() external payable {
        require(msg.value > 0, "Must deposit a positive amount as collateral");

        collateralBalances[msg.sender] += msg.value;

        emit CollateralDeposited(msg.sender, msg.value);
    }

    // 安全提取其抵押品时发生
    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "Must withdraw a positive amount");
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");

        // 检查欠多少债务
        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        // 计算他们需要多少抵押品才能保持安全
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;

        // 如果你抵押了这笔资产会发生什么？
        require(
            collateralBalances[msg.sender] - amount >= requiredCollateral, //要有足够的余额
            "Withdrawal would break collateral ratio"
        );

        // 通过所有检查，更新记录
        collateralBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit CollateralWithdrawn(msg.sender, amount);
    }

    // 借钱
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
    // 还贷
    function repay() external payable {
        require(msg.value > 0, "Must repay a positive amount");

        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt > 0, "No debt to repay");

        uint256 amountToRepay = msg.value;
        if (amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt); // Refund the extra
        }

        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);
    }

    // ==========get工具函数========== //
    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }

    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }

}