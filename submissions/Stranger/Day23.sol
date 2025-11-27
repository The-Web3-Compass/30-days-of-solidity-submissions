// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 基础的DeFi借贷平台
contract SimpleLending {
    // 用户存入的ETH余额
    mapping(address => uint256) public depositBalances;

    // 用户的贷款余额, 及用户从借贷池借的ETH数量
    mapping(address => uint256) public borrowBalances;

    // 用户的抵押ETH余额
    mapping(address => uint256) public collateralBalances;

    // 贷款年化利率基点 (1% 是1个基点, 500个基点是 5%)
    uint256 public interestRateBasisPoints = 500;

    // 贷款价值比(loan to value, ltv), ltv = 最大可贷款金额 / 抵押品金额。7500个基点即75%, 即10000的抵押品最多可贷款7500
    uint256 public collateralFactorBasisPoints = 7500;

    // 上次计算利息的时间戳
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    // Events
    event Deposit(address indexed user, uint256 amount);             // 存款事件
    event Withdraw(address indexed user, uint256 amount);            // 提款事件
    event Borrow(address indexed user, uint256 amount);              // 借款(借入)事件
    event Repay(address indexed user, uint256 amount);               // 还贷事件
    event CollateralDeposited(address indexed user, uint256 amount); // 质押(提供质押品)事件
    event CollateralWithdrawn(address indexed user, uint256 amount); // 提取质押品事件

    // 向借贷池中存入ETH
    function deposit() external payable {
        require(msg.value > 0, "Must deposit a positive amount");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // 从借贷池中提取ETH
    function withdraw(uint256 amount) external {
        require(amount > 0, "Must withdraw a positive amount");
        require(depositBalances[msg.sender] >= amount, "Insufficient balance");
        depositBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // 锁定抵押的ETH
    function depositCollateral() external payable {
        require(msg.value > 0, "Must deposit a positive amount as collateral");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    // 提取抵押的ETH
    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "Must withdraw a positive amount");
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");

        // 计算最新债务
        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        // 计算需要的抵押品金额
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;

        // 确保余额需>=所需的抵押品余额
        require(
            collateralBalances[msg.sender] - amount >= requiredCollateral,
            "Withdrawal would break collateral ratio"
        );

        collateralBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    // 借款
    function borrow(uint256 amount) external {
        require(amount > 0, "Must borrow a positive amount");
        require(address(this).balance >= amount, "Not enough liquidity in the pool");

        // 计算最大可借款金额
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        // 更新债务
        uint256 currentDebt = calculateInterestAccrued(msg.sender);

        // 已经发生的债务与本次借款金额之和<=最大可借款金额
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
            // 如果提交的还款额大于需要的还款金额则退回钱包
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt);
        }

        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);
    }

    // 计算累积的利息
    function calculateInterestAccrued(address user) public view returns (uint256) {
        if (borrowBalances[user] == 0) {
            return 0;
        }
        // 自上次计算利息距今的时间差
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        // 更新利息, 单位似乎对不上
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);
        // 计算总债务
        return borrowBalances[user] + interest;
    }

    // 获取最大可借款金额
    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }

    // 检查借贷池余额
    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }
}

