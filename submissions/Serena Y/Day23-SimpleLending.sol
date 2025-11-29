// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleLending
 * @dev A basic DeFi lending and borrowing platform
 */
contract SimpleLending {
    // Token balances for each user
    mapping(address => uint256) public depositBalances;
    //用户地址-存入借贷池子的eth数量

    // Borrowed amounts for each user
    mapping(address => uint256) public borrowBalances;
    //用户地址-借款账本

    // Collateral provided by each user
    mapping(address => uint256) public collateralBalances;
    //用户地址-抵押的eth数量 相当于押金 在不安全时保护系统

    // Interest rate in basis points (1/100 of a percent)
    // 500 basis points = 5% interest
    uint256 public interestRateBasisPoints = 500;
    //百分之五的年化利率，

    // Collateral factor in basis points (e.g., 7500 = 75%)
    // Determines how much you can borrow against your collateral
    uint256 public collateralFactorBasisPoints = 7500;
    //抵押借贷的百分比，百分之75，也就是说用户只能借抵押价值百分之75的贷款

    // Timestamp of last interest accrual
    mapping(address => uint256) public lastInterestAccrualTimestamp;
    //上次利息检查的时间戳 （我们不能每时每秒计算，因为gas费太贵了）

    // Events
    event Deposit(address indexed user, uint256 amount);//事件：用户A 刚刚存入了 数量B的eth
    event Withdraw(address indexed user, uint256 amount);//事件：用户A 刚刚取出了数量B的eth
    event Borrow(address indexed user, uint256 amount);//事件：用户A刚刚借出了数量B的eth
    event Repay(address indexed user, uint256 amount);//事件：用户A刚刚偿还贷款B
    event CollateralDeposited(address indexed user, uint256 amount);//事件：用户A存入抵押款存入了抵押款B
    event CollateralWithdrawn(address indexed user, uint256 amount);//事件：用户A剩余抵押品数量B

    function deposit() external payable {//存入eth
        require(msg.value > 0, "Must deposit a positive amount");//存入金额大于0
        depositBalances[msg.sender] += msg.value;//账本余额增加
        emit Deposit(msg.sender, msg.value);//公告：msg.seder 存入了msg.value的eth
    }

    function withdraw(uint256 amount) external {//提现
        require(amount > 0, "Must withdraw a positive amount");//提现金额大于0
        require(depositBalances[msg.sender] >= amount, "Insufficient balance");//提现金额小于账本余额
        depositBalances[msg.sender] -= amount;//账本余额减去提现金额
        payable(msg.sender).transfer(amount);//转账，转给msg.sender amount数量的钱
        emit Withdraw(msg.sender, amount);//公告：msg.sender 提取了amount的钱
    }

    function depositCollateral() external payable {//存入抵押
        require(msg.value > 0, "Must deposit a positive amount as collateral");//存入抵押必须大于0
        collateralBalances[msg.sender] += msg.value;//抵押账本更新
        emit CollateralDeposited(msg.sender, msg.value);//公告 msg.sender存入了msg.value的金额押金
    }

    function withdrawCollateral(uint256 amount) external {//提取抵押款
        require(amount > 0, "Must withdraw a positive amount");//提取数量大于0
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");
        //抵押金余额大于提取数量

        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        //贷款金额=贷款账本+利息
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;
        //需要的押金

        require(
            collateralBalances[msg.sender] - amount >= requiredCollateral,
            //需要满足押金减去提款大于最低要求押金
            "Withdrawal would break collateral ratio"
        );

        collateralBalances[msg.sender] -= amount;//抵押金额减去提取数量
        payable(msg.sender).transfer(amount);//向msg.sender 转帐
        emit CollateralWithdrawn(msg.sender, amount);//公告 抵押品提取 msg.sender提取了 amount的抵押品
    }

    function borrow(uint256 amount) external {
        //贷款函数
        require(amount > 0, "Must borrow a positive amount");
        //贷款金额必须大于0
        require(address(this).balance >= amount, "Not enough liquidity in the pool");
        //合约余额必须大于贷款金额

        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        //最大贷款金额等于 抵押金额*75%
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        //当前债务=等于债务加上利息

        require(currentDebt + amount <= maxBorrowAmount, "Exceeds allowed borrow amount");
        //需要满足当前债务加上新借款金额小于最大借款金额

        borrowBalances[msg.sender] = currentDebt + amount;
        //借款金额=当前债务加上新借款金额
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        //上一次更新利息时间更新为当前时间戳

        payable(msg.sender).transfer(amount);//向msg.sender发放贷款
        emit Borrow(msg.sender, amount);//公告 msg.sender 借款多少
    }

    function repay() external payable {
        //偿还贷款函数
        require(msg.value > 0, "Must repay a positive amount");
        //需要满足金额大于0
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        //计算当前欠款总额
        require(currentDebt > 0, "No debt to repay");
        //检查当前欠款是否大于0

        uint256 amountToRepay = msg.value;//还款金额
        if (amountToRepay > currentDebt) {//如果还款金额大于总欠款
            amountToRepay = currentDebt;//还款金额等于总欠款
            payable(msg.sender).transfer(msg.value - currentDebt);//返回msg.sender多余的钱
        }

        borrowBalances[msg.sender] = currentDebt - amountToRepay;//借款金额更新 减去还款金额
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;//时间戳更新

        emit Repay(msg.sender, amountToRepay);//公告，谁还了多少钱
    }

    function calculateInterestAccrued(address user) public view returns (uint256) {
        //计算利率函数返回借款加利率
        if (borrowBalances[user] == 0) {//贷款账本余额为0则返回0
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        //事件间隔=当前时间戳-上次检查的时间
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);
        //利率等于 贷款账本*百分之5利率*时间/365天

        return borrowBalances[user] + interest;
        //返回贷款站本加利率 {总债务} = {原始借款金额} + {累积利息}
    }

    function getMaxBorrowAmount(address user) external view returns (uint256) {
        //最大借款函数 返回值
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
        //返回抵押金额*比例/10000 也就是百分之75
    }

    function getTotalLiquidity() external view returns (uint256) {
        //获得整个流动性
        return address(this).balance;
        //返回该合约的所有余额
    }
}

